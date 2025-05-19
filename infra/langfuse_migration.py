import json
from pathlib import Path
from typing import Optional
from urllib.parse import urljoin

import requests
import typer
from langfuse import Langfuse
from requests.auth import HTTPBasicAuth
from rich.console import Console
from rich.panel import Panel
from rich.progress import (
    BarColumn,
    Progress,
    SpinnerColumn,
    TaskProgressColumn,
    TextColumn,
)
from rich.prompt import Confirm
from rich.table import Table

console = Console()
app = typer.Typer(name="server-manager", help="CLI tool to manage server operations")


@app.command()
def transfer_prompts():
    """Transfer prompts from source Langfuse instance to destination Langfuse instance"""

    console.print(Panel.fit("[bold blue]Langfuse Prompt Transfer Tool[/bold blue]", subtitle="Transfer prompts between instances", border_style="blue"))

    # Get connection details from user input
    console.print("[yellow]Enter source Langfuse details:[/yellow]")
    source_host = typer.prompt("Source host URL")
    source_public_key = typer.prompt("Source public key")
    source_secret_key = typer.prompt("Source secret key", hide_input=True)

    console.print("\n[yellow]Enter destination Langfuse details:[/yellow]")
    dest_host = typer.prompt("Destination host URL")
    dest_public_key = typer.prompt("Destination public key")
    dest_secret_key = typer.prompt("Destination secret key", hide_input=True)

    prompt_list_path = typer.prompt("Path to prompt list file (optional)", default="")

    console.print(f"[yellow]Source:[/yellow] {source_host}")
    console.print(f"[yellow]Destination:[/yellow] {dest_host}")

    # Initialize Langfuse clients
    with console.status("[bold green]Initializing Langfuse clients...[/bold green]"):
        source_langfuse = Langfuse(public_key=source_public_key, secret_key=source_secret_key, host=source_host)

        dest_langfuse = Langfuse(public_key=dest_public_key, secret_key=dest_secret_key, host=dest_host)

    # Get prompt lists (either from file or use defaults)
    if Path(prompt_list_path).exists():
        with console.status("[bold green]Loading prompts from file...[/bold green]"):
            with open(prompt_list_path, "r") as f:
                prompt_data = json.load(f)

                if prompt_data.get("text_prompts") is None or prompt_data.get("chat_prompts") is None:
                    console.print("[bold red]Invalid prompt list file format! Make sure the input file format is correct.[/bold red]")
                    return

                text_prompts = prompt_data.get("text_prompts", [])
                chat_prompts = prompt_data.get("chat_prompts", [])

        console.print(f"[green]Successfully loaded prompts from file:[/green] {len(text_prompts)} text prompts, {len(chat_prompts)} chat prompts")
    else:
        console.print(f"[yellow]File not found:[/yellow] {prompt_list_path}")
        migrate_all = Confirm.ask("Would you like to fetch all prompts from source?", default=True)

        if migrate_all:
            console.print("\n[bold blue]Fetching prompts from source Langfuse...[/bold blue]")
            text_prompts = []
            chat_prompts = []
            all_prompts_data = []

            # Get all prompts by fetching multiple pages
            with Progress(SpinnerColumn(), TextColumn("[bold blue]{task.description}[/bold blue]"), BarColumn(), TaskProgressColumn(), console=console) as progress:
                fetch_task = progress.add_task("[bold blue]Fetching prompt pages...", total=10)

                for page in range(1, 11):  # Fetch up to 10 pages
                    try:
                        response = requests.get(urljoin(source_host, "/api/public/v2/prompts"), params={"limit": 100, "page": page}, auth=HTTPBasicAuth(username=source_public_key, password=source_secret_key))
                        response.raise_for_status()

                        data = response.json()
                        if not data.get("data"):
                            progress.update(fetch_task, description=f"[bold green]Completed! No more data after page {page-1}[/bold green]")
                            break  # Exit if no more data

                        all_prompts_data.extend(data["data"])
                        progress.update(fetch_task, advance=1, description=f"Retrieved page {page} with {len(data['data'])} prompts")

                        # Exit early if we've reached the last page
                        if page >= data.get("meta", {}).get("totalPages", 1):
                            progress.update(fetch_task, description=f"[bold green]Completed! Reached last page ({page})[/bold green]")
                            break

                    except Exception as e:
                        progress.update(fetch_task, description=f"[bold red]Error on page {page}: {str(e)}[/bold red]")
                        break

            # Categorize prompts by type
            console.print("\n[bold blue]Categorizing prompts by type...[/bold blue]")
            with Progress(SpinnerColumn(), TextColumn("[bold blue]{task.description}[/bold blue]"), BarColumn(), TaskProgressColumn(), console=console) as progress:
                categorize_task = progress.add_task("[bold blue]Processing prompts...", total=len(all_prompts_data))

                for prompt in all_prompts_data:
                    try:
                        prompt_detail = requests.get(urljoin(source_host, f'/api/public/v2/prompts/{prompt["name"]}'), auth=HTTPBasicAuth(username=source_public_key, password=source_secret_key))
                        prompt_detail.raise_for_status()

                        prompt_type = prompt_detail.json().get("type")
                        if prompt_type == "text":
                            text_prompts.append(prompt["name"])
                            progress.update(categorize_task, advance=1, description=f"Found text prompt: {prompt['name']}")
                        elif prompt_type == "chat":
                            chat_prompts.append(prompt["name"])
                            progress.update(categorize_task, advance=1, description=f"Found chat prompt: {prompt['name']}")
                        else:
                            progress.update(categorize_task, advance=1, description=f"Unknown type for: {prompt['name']}")
                    except Exception as e:
                        progress.update(categorize_task, advance=1, description=f"[red]Error with prompt {prompt['name']}[/red]")

            # Display summary table
            table = Table(title="Prompt Summary")
            table.add_column("Type", style="cyan")
            table.add_column("Count", style="green")
            table.add_row("Text Prompts", str(len(text_prompts)))
            table.add_row("Chat Prompts", str(len(chat_prompts)))
            table.add_row("Total", str(len(text_prompts) + len(chat_prompts)))
            console.print(table)
        else:
            console.print("[bold yellow]No prompt list file provided and user opted not to fetch all prompts. Exiting.[/bold yellow]")
            return

    # Transfer text prompts
    console.print("\n[bold blue]Starting transfer of prompts...[/bold blue]")

    # Transfer text prompts
    console.rule("[bold blue]Text Prompts[/bold blue]")
    with Progress(SpinnerColumn(), TextColumn("[bold blue]{task.description}[/bold blue]"), BarColumn(), TaskProgressColumn(), console=console) as progress:
        text_task = progress.add_task(f"Transferring text prompts...", total=len(text_prompts))

        success_count = 0
        for prompt_name in text_prompts:
            try:
                prompt = source_langfuse.get_prompt(prompt_name)
                # Uncomment below lines to actually create prompts on destination
                dest_langfuse.create_prompt(name=prompt_name, prompt=prompt.compile(), type="text", is_active=True)
                success_count += 1
                progress.update(text_task, advance=1, description=f"Transferred: {prompt_name}")
            except Exception as e:
                progress.update(text_task, advance=1, description=f"[bold red]Failed: {prompt_name} - {str(e)}[/bold red]")

    # Transfer chat prompts
    console.rule("[bold blue]Chat Prompts[/bold blue]")
    with Progress(SpinnerColumn(), TextColumn("[bold blue]{task.description}[/bold blue]"), BarColumn(), TaskProgressColumn(), console=console) as progress:
        chat_task = progress.add_task(f"Transferring chat prompts...", total=len(chat_prompts))

        success_count = 0
        for prompt_name in chat_prompts:
            try:
                prompt = source_langfuse.get_prompt(prompt_name)
                # Uncomment below lines to actually create prompts on destination
                dest_langfuse.create_prompt(name=prompt_name, prompt=prompt.compile(), type="chat", is_active=True)
                success_count += 1
                progress.update(chat_task, advance=1, description=f"Transferred: {prompt_name}")
            except Exception as e:
                progress.update(chat_task, advance=1, description=f"[bold red]Failed: {prompt_name} - {str(e)}[/bold red]")

    # Final summary
    console.print(Panel.fit(f"[bold green]Transfer completed![/bold green]\n" f"• {len(text_prompts)} text prompts processed\n" f"• {len(chat_prompts)} chat prompts processed", title="Summary", border_style="green"))


if __name__ == "__main__":
    app()
