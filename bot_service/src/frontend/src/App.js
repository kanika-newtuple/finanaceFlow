import React, { useState, useEffect } from 'react';
import {
  Box, 
  Grid,
  Typography, 
  Button, 
  Paper, 
  Table, 
  TableBody, 
  TableCell, 
  TableContainer, 
  TableHead, 
  TableRow,
  CircularProgress,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Snackbar,
  Alert,
  IconButton,
  Collapse,
  Card,
  CardContent,
  Chip,
  Divider,
  Avatar,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  AppBar,
  Toolbar,
  Drawer,
  ListItemButton,
  Badge,
  Tabs,
  Tab,
  TextField,
  InputAdornment,
  Menu,
  MenuItem,
  Switch,
  FormControlLabel
} from '@mui/material';
import { 
  CloudUpload, 
  Dashboard,
  Receipt,
  Analytics,
  AccountBalance,
  TrendingUp,
  TrendingDown,
  AttachMoney,
  Business,
  Schedule,
  FilterList,
  Search,
  MoreVert,
  Delete,
  Visibility,
  GetApp,
  Notifications,
  Settings,
  DarkMode,
  LightMode,
  ExpandMore,
  ExpandLess,
  PieChart,
  BarChart,
  Timeline
} from '@mui/icons-material';
import { createTheme, ThemeProvider } from '@mui/material/styles';
import { Line, Bar, Doughnut } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement,
} from 'chart.js';

// Register Chart.js components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement
);

const API_BASE_URL = 'http://localhost:8081/api/v1';

function App() {
  const [bills, setBills] = useState([]);
  const [loading, setLoading] = useState(false);
  const [uploadLoading, setUploadLoading] = useState(false);
  const [selectedFiles, setSelectedFiles] = useState([]);
  const [openDialog, setOpenDialog] = useState(false);
  const [selectedBill, setSelectedBill] = useState(null);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'info' });
  const [expandedBill, setExpandedBill] = useState(null);
  const [darkMode, setDarkMode] = useState(true);
  const [currentTab, setCurrentTab] = useState(0);
  const [searchTerm, setSearchTerm] = useState('');
  const [anchorEl, setAnchorEl] = useState(null);
  const [openDeleteDialog, setOpenDeleteDialog] = useState(false);
  const [billToDelete, setBillToDelete] = useState(null);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [currentUploadFile, setCurrentUploadFile] = useState('');

  // Create theme
  const theme = createTheme({
    palette: {
      mode: darkMode ? 'dark' : 'light',
      primary: {
        main: darkMode ? '#00d4aa' : '#387002',
      },
      secondary: {
        main: darkMode ? '#ff6b6b' : '#e53e3e',
      },
      background: {
        default: darkMode ? '#0d1117' : '#f8fafc',
        paper: darkMode ? '#161b22' : '#ffffff',
      },
      success: {
        main: '#00d4aa',
      },
      error: {
        main: '#ff6b6b',
      },
    },
    typography: {
      fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
      h4: {
        fontWeight: 600,
      },
      h6: {
        fontWeight: 500,
      },
    },
    components: {
      MuiCard: {
        styleOverrides: {
          root: {
            borderRadius: 12,
            boxShadow: darkMode 
              ? '0 4px 20px rgba(0, 0, 0, 0.3)' 
              : '0 4px 20px rgba(0, 0, 0, 0.08)',
          },
        },
      },
      MuiButton: {
        styleOverrides: {
          root: {
            borderRadius: 8,
            textTransform: 'none',
            fontWeight: 500,
          },
        },
      },
    },
  });

  // Fetch bills on component mount
  useEffect(() => {
    fetchBills();
  }, []);

  // Function to fetch bills from API
  const fetchBills = async () => {
    setLoading(true);
    try {
      const response = await fetch(`${API_BASE_URL}/bills`);
      if (!response.ok) {
        throw new Error(`Error: ${response.status}`);
      }
      const data = await response.json();
      setBills(data);
    } catch (error) {
      console.error('Error fetching bills:', error);
      showSnackbar('Failed to load bills', 'error');
    } finally {
      setLoading(false);
    }
  };

  // Handle multiple file upload
  const handleUpload = async () => {
    if (selectedFiles.length === 0) {
      showSnackbar('Please select at least one file', 'warning');
      return;
    }

    // Validate all files are PDFs
    const invalidFiles = selectedFiles.filter(file => !file.name.toLowerCase().endsWith('.pdf'));
    if (invalidFiles.length > 0) {
      showSnackbar(`Invalid files detected: ${invalidFiles.map(f => f.name).join(', ')}. Only PDF files are allowed.`, 'error');
      return;
    }

    setUploadLoading(true);
    setUploadProgress(0);
    const successfulUploads = [];
    const failedUploads = [];

    try {
      // Process files one by one to avoid overwhelming the server
      for (let i = 0; i < selectedFiles.length; i++) {
        const file = selectedFiles[i];
        setCurrentUploadFile(file.name);
        setUploadProgress(((i) / selectedFiles.length) * 100);
        
        const formData = new FormData();
        formData.append('file', file);

        try {
          showSnackbar(`Processing ${file.name} (${i + 1}/${selectedFiles.length})...`, 'info');
          
          const response = await fetch(`${API_BASE_URL}/bills/upload`, {
            method: 'POST',
            body: formData,
          });

          if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.detail || `Error: ${response.status}`);
          }

          const data = await response.json();
          successfulUploads.push({ file: file.name, data });
        } catch (error) {
          console.error(`Error uploading ${file.name}:`, error);
          failedUploads.push({ file: file.name, error: error.message });
        }
      }
      
      setUploadProgress(100);

      // Update bills list with successful uploads
      if (successfulUploads.length > 0) {
        const newBills = successfulUploads.map(upload => upload.data);
        setBills([...bills, ...newBills]);
      }

      // Show results
      if (successfulUploads.length > 0 && failedUploads.length === 0) {
        showSnackbar(`All ${successfulUploads.length} files processed successfully!`, 'success');
      } else if (successfulUploads.length > 0 && failedUploads.length > 0) {
        showSnackbar(`${successfulUploads.length} files processed successfully, ${failedUploads.length} failed`, 'warning');
      } else {
        showSnackbar(`All ${failedUploads.length} files failed to process`, 'error');
      }

      // Reset selection
      setSelectedFiles([]);
      document.getElementById('file-upload').value = '';
      
    } catch (error) {
      console.error('Error in bulk upload:', error);
      showSnackbar(`Bulk upload failed: ${error.message}`, 'error');
    } finally {
      setUploadLoading(false);
    }
  };

  // Calculate dashboard metrics
  const getDashboardMetrics = () => {
    const totalBills = bills.length;
    const totalAmount = bills.reduce((sum, bill) => sum + (bill.total_amount || 0), 0);
    const thisMonth = new Date().getMonth();
    const thisYear = new Date().getFullYear();
    
    const thisMonthBills = bills.filter(bill => {
      const billDate = new Date(bill.bill_date);
      return billDate.getMonth() === thisMonth && billDate.getFullYear() === thisYear;
    });
    
    const monthlyAmount = thisMonthBills.reduce((sum, bill) => sum + (bill.total_amount || 0), 0);
    
    // Get vendor distribution
    const vendorDistribution = bills.reduce((acc, bill) => {
      const vendor = bill.vendor || 'Unknown';
      acc[vendor] = (acc[vendor] || 0) + bill.total_amount;
      return acc;
    }, {});

    return {
      totalBills,
      totalAmount,
      monthlyAmount,
      thisMonthBills: thisMonthBills.length,
      vendorDistribution,
    };
  };

  const metrics = getDashboardMetrics();

  // Chart data
  const chartData = {
    labels: Object.keys(metrics.vendorDistribution).slice(0, 6),
    datasets: [
      {
        label: 'Amount by Vendor',
        data: Object.values(metrics.vendorDistribution).slice(0, 6),
        backgroundColor: [
          '#00d4aa',
          '#ff6b6b',
          '#4ecdc4',
          '#45b7d1',
          '#f9ca24',
          '#f0932b',
        ],
      },
    ],
  };

  // Monthly trend data
  const monthlyTrendData = {
    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    datasets: [
      {
        label: 'Monthly Expenses',
        data: [12000, 19000, 3000, 5000, 2000, 3000],
        borderColor: '#00d4aa',
        backgroundColor: 'rgba(0, 212, 170, 0.1)',
        tension: 0.4,
      },
    ],
  };

  // Format currency
  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  // Format date
  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  // Show snackbar notification
  const showSnackbar = (message, severity) => {
    setSnackbar({ open: true, message, severity });
  };

  // Download bills as CSV
  const downloadCSV = () => {
    try {
      // Create CSV headers
      const headers = [
        'ID',
        'Vendor',
        'Bill ID',
        'Date',
        'Due Date',
        'Document Type',
        'Currency',
        'Total Amount',
        'Payment Terms',
        'Previous Balance',
        'Vendor Address',
        'Vendor Contact',
        'Recipient Name',
        'Recipient Address',
        'Transaction Count'
      ];

      // Create CSV rows
      const csvRows = [
        headers.join(','), // Header row
        ...bills.map(bill => [
          bill.id,
          `"${bill.vendor || ''}"`,
          `"${bill.bill_id || ''}"`,
          formatDate(bill.bill_date),
          bill.due_date ? formatDate(bill.due_date) : '',
          `"${bill.document_type || ''}"`,
          bill.currency || 'USD',
          bill.total_amount || 0,
          `"${bill.payment_terms || ''}"`,
          bill.previous_balance || 0,
          `"${bill.vendor_address || ''}"`,
          `"${bill.vendor_contact || ''}"`,
          `"${bill.recipient_name || ''}"`,
          `"${bill.recipient_address || ''}"`,
          bill.transactions ? bill.transactions.length : 0
        ].join(','))
      ];

      // Create and download the file
      const csvContent = csvRows.join('\n');
      const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
      const link = document.createElement('a');
      
      if (link.download !== undefined) {
        const url = URL.createObjectURL(blob);
        link.setAttribute('href', url);
        link.setAttribute('download', `bills_export_${new Date().toISOString().split('T')[0]}.csv`);
        link.style.visibility = 'hidden';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        
        showSnackbar('Bills exported to CSV successfully', 'success');
      }
    } catch (error) {
      console.error('Error downloading CSV:', error);
      showSnackbar('Error downloading CSV file', 'error');
    }
  };

  // Download detailed transactions CSV
  const downloadTransactionsCSV = () => {
    try {
      // Create CSV headers for transactions
      const headers = [
        'Bill ID',
        'Vendor',
        'Bill Date',
        'Transaction Date',
        'Description',
        'Category',
        'Table Section',
        'Quantity',
        'Unit Price',
        'Total Price',
        'Notes'
      ];

      // Create CSV rows for all transactions
      const csvRows = [headers.join(',')];
      
      bills.forEach(bill => {
        if (bill.transactions && bill.transactions.length > 0) {
          bill.transactions.forEach(transaction => {
            csvRows.push([
              bill.id,
              `"${bill.vendor || ''}"`,
              formatDate(bill.bill_date),
              transaction.transaction_date ? formatDate(transaction.transaction_date) : '',
              `"${transaction.description || ''}"`,
              `"${transaction.category || ''}"`,
              `"${transaction.table_section || ''}"`,
              transaction.quantity || '',
              transaction.unit_price || '',
              transaction.total_price || 0,
              `"${transaction.notes || ''}"`
            ].join(','));
          });
        }
      });

      // Create and download the file
      const csvContent = csvRows.join('\n');
      const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
      const link = document.createElement('a');
      
      if (link.download !== undefined) {
        const url = URL.createObjectURL(blob);
        link.setAttribute('href', url);
        link.setAttribute('download', `transactions_export_${new Date().toISOString().split('T')[0]}.csv`);
        link.style.visibility = 'hidden';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        
        showSnackbar('Transactions exported to CSV successfully', 'success');
      }
    } catch (error) {
      console.error('Error downloading transactions CSV:', error);
      showSnackbar('Error downloading transactions CSV file', 'error');
    }
  };

  // Handle snackbar close
  const handleSnackbarClose = () => {
    setSnackbar({ ...snackbar, open: false });
  };

  // Handle delete bill
  const handleDeleteClick = (bill) => {
    setBillToDelete(bill);
    setOpenDeleteDialog(true);
  };

  // Close delete dialog
  const handleCloseDeleteDialog = () => {
    setOpenDeleteDialog(false);
    setBillToDelete(null);
  };

  // Confirm delete bill
  const handleConfirmDelete = async () => {
    if (!billToDelete) return;

    try {
      const response = await fetch(`${API_BASE_URL}/bills/${billToDelete.id}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        throw new Error(`Error: ${response.status}`);
      }

      // Remove the deleted bill from the state
      setBills(bills.filter(bill => bill.id !== billToDelete.id));
      showSnackbar('Bill deleted successfully', 'success');
    } catch (error) {
      console.error('Error deleting bill:', error);
      showSnackbar('Failed to delete bill', 'error');
    } finally {
      setOpenDeleteDialog(false);
      setBillToDelete(null);
    }
  };

  // Filter bills based on search
  const filteredBills = bills.filter(bill =>
    bill.vendor?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    bill.bill_id?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  // Dashboard view
  const DashboardView = () => (
    <Box>
      {/* Key Metrics Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography color="textSecondary" gutterBottom variant="body2">
                    Total Bills
                  </Typography>
                  <Typography variant="h4" component="div">
                    {metrics.totalBills}
                  </Typography>
                </Box>
                <Avatar sx={{ bgcolor: 'primary.main' }}>
                  <Receipt />
                </Avatar>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography color="textSecondary" gutterBottom variant="body2">
                    Total Amount
                  </Typography>
                  <Typography variant="h4" component="div">
                    {formatCurrency(metrics.totalAmount)}
                  </Typography>
                </Box>
                <Avatar sx={{ bgcolor: 'success.main' }}>
                  <AttachMoney />
                </Avatar>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography color="textSecondary" gutterBottom variant="body2">
                    This Month
                  </Typography>
                  <Typography variant="h4" component="div">
                    {formatCurrency(metrics.monthlyAmount)}
                  </Typography>
                  <Typography variant="body2" color="success.main">
                    {metrics.thisMonthBills} bills
                  </Typography>
                </Box>
                <Avatar sx={{ bgcolor: 'info.main' }}>
                  <TrendingUp />
                </Avatar>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography color="textSecondary" gutterBottom variant="body2">
                    Avg. Bill Amount
                  </Typography>
                  <Typography variant="h4" component="div">
                    {formatCurrency(metrics.totalAmount / (metrics.totalBills || 1))}
                  </Typography>
                </Box>
                <Avatar sx={{ bgcolor: 'warning.main' }}>
                  <Analytics />
                </Avatar>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Charts */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Monthly Expense Trend
              </Typography>
              <Box sx={{ height: 300 }}>
                <Line 
                  data={monthlyTrendData} 
                  options={{
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                      legend: {
                        display: false,
                      },
                    },
                    scales: {
                      y: {
                        beginAtZero: true,
                      },
                    },
                  }}
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Vendor Distribution
              </Typography>
              <Box sx={{ height: 300 }}>
                <Doughnut 
                  data={chartData}
                  options={{
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                      legend: {
                        position: 'bottom',
                      },
                    },
                  }}
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Recent Bills */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Recent Bills
          </Typography>
          <List>
            {bills.slice(0, 5).map((bill) => (
              <ListItem key={bill.id} divider>
                <ListItemIcon>
                  <Avatar sx={{ bgcolor: 'primary.main', width: 32, height: 32 }}>
                    <Receipt fontSize="small" />
                  </Avatar>
                </ListItemIcon>
                <ListItemText
                  primary={bill.vendor}
                  secondary={`${formatDate(bill.bill_date)} • ${bill.bill_id || 'No ID'}`}
                />
                <Typography variant="h6" color="primary">
                  {formatCurrency(bill.total_amount)}
                </Typography>
              </ListItem>
            ))}
          </List>
        </CardContent>
      </Card>
    </Box>
  );

  // Bills view
  const BillsView = () => (
    <Box>
      {/* Upload Section */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Upload New Bill
          </Typography>
                     <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, flexWrap: 'wrap' }}>
             <Button
               variant="outlined"
               component="label"
               startIcon={<CloudUpload />}
               sx={{ minWidth: 250 }}
             >
               {selectedFiles.length > 0 
                 ? `${selectedFiles.length} file${selectedFiles.length > 1 ? 's' : ''} selected`
                 : 'Select PDF Files (Multiple)'
               }
               <input
                 id="file-upload"
                 type="file"
                 accept=".pdf"
                 multiple
                 hidden
                 onChange={(e) => setSelectedFiles(Array.from(e.target.files))}
               />
             </Button>
             <Button
               variant="contained"
               onClick={handleUpload}
               disabled={selectedFiles.length === 0 || uploadLoading}
               sx={{ minWidth: 140 }}
             >
               {uploadLoading ? <CircularProgress size={24} /> : `Process ${selectedFiles.length || ''} Bill${selectedFiles.length !== 1 ? 's' : ''}`}
             </Button>
             {selectedFiles.length > 0 && (
               <Button
                 variant="text"
                 onClick={() => {
                   setSelectedFiles([]);
                   document.getElementById('file-upload').value = '';
                 }}
                 size="small"
               >
                 Clear Selection
               </Button>
             )}
           </Box>
           
           {/* Show selected files */}
           {selectedFiles.length > 0 && (
             <Box sx={{ mt: 2 }}>
               <Typography variant="subtitle2" gutterBottom>
                 Selected Files:
               </Typography>
               <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                 {selectedFiles.map((file, index) => (
                   <Chip
                     key={index}
                     label={file.name}
                     size="small"
                     variant="outlined"
                     onDelete={() => {
                       const newFiles = selectedFiles.filter((_, i) => i !== index);
                       setSelectedFiles(newFiles);
                     }}
                     sx={{ maxWidth: 200 }}
                   />
                 ))}
               </Box>
             </Box>
           )}
        </CardContent>
      </Card>

      {/* Search and Filter */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
            <TextField
              placeholder="Search bills..."
              variant="outlined"
              size="small"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <Search />
                  </InputAdornment>
                ),
              }}
              sx={{ flexGrow: 1 }}
            />
            <Button startIcon={<FilterList />} variant="outlined">
              Filter
            </Button>
            <Button 
              startIcon={<GetApp />} 
              variant="outlined"
              onClick={downloadCSV}
              disabled={bills.length === 0}
            >
              Export Bills
            </Button>
            <Button 
              startIcon={<GetApp />} 
              variant="outlined"
              onClick={downloadTransactionsCSV}
              disabled={bills.length === 0}
            >
              Export Transactions
            </Button>
          </Box>
        </CardContent>
      </Card>

      {/* Bills Table */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            All Bills ({filteredBills.length})
          </Typography>
          
          {loading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
              <CircularProgress />
            </Box>
          ) : filteredBills.length === 0 ? (
            <Box sx={{ textAlign: 'center', p: 3 }}>
              <Typography variant="body1" color="textSecondary">
                No bills found. Upload a bill to get started.
              </Typography>
            </Box>
          ) : (
            <TableContainer>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Vendor</TableCell>
                    <TableCell>Date</TableCell>
                    <TableCell>Amount</TableCell>
                    <TableCell>Type</TableCell>
                    <TableCell>Status</TableCell>
                    <TableCell>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {filteredBills.map((bill) => (
                    <React.Fragment key={bill.id}>
                      <TableRow hover>
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <Avatar sx={{ width: 32, height: 32, bgcolor: 'primary.main' }}>
                              <Business fontSize="small" />
                            </Avatar>
                            <Box>
                              <Typography variant="body2" fontWeight={500}>
                                {bill.vendor}
                              </Typography>
                              <Typography variant="caption" color="textSecondary">
                                {bill.bill_id || 'No ID'}
                              </Typography>
                            </Box>
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {formatDate(bill.bill_date)}
                          </Typography>
                          {bill.due_date && (
                            <Typography variant="caption" color="textSecondary">
                              Due: {formatDate(bill.due_date)}
                            </Typography>
                          )}
                        </TableCell>
                        <TableCell>
                          <Typography variant="h6" color="primary">
                            {formatCurrency(bill.total_amount)}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Chip 
                            label={bill.document_type || 'Bill'} 
                            size="small"
                            variant="outlined"
                          />
                        </TableCell>
                        <TableCell>
                          <Chip 
                            label="Processed" 
                            size="small"
                            color="success"
                          />
                        </TableCell>
                        <TableCell>
                          <Box sx={{ display: 'flex', gap: 1 }}>
                            <IconButton
                              size="small"
                              onClick={() => setExpandedBill(expandedBill === bill.id ? null : bill.id)}
                            >
                              {expandedBill === bill.id ? <ExpandLess /> : <ExpandMore />}
                            </IconButton>
                                                         <IconButton size="small">
                               <Visibility />
                             </IconButton>
                             <IconButton 
                               size="small" 
                               color="error"
                               onClick={() => handleDeleteClick(bill)}
                             >
                               <Delete />
                             </IconButton>
                          </Box>
                        </TableCell>
                      </TableRow>
                      
                      {/* Expanded Transaction Details */}
                      <TableRow>
                        <TableCell colSpan={6} sx={{ py: 0 }}>
                          <Collapse in={expandedBill === bill.id}>
                            <Box sx={{ p: 3, bgcolor: 'background.default' }}>
                              <Typography variant="h6" gutterBottom>
                                Transaction Details
                              </Typography>
                              
                              {/* Bill Info */}
                              <Grid container spacing={3} sx={{ mb: 3 }}>
                                <Grid item xs={12} md={6}>
                                  <Typography variant="subtitle2" gutterBottom>
                                    Vendor Information
                                  </Typography>
                                  <Typography variant="body2">
                                    {bill.vendor_address || 'Address not available'}
                                  </Typography>
                                  <Typography variant="body2">
                                    {bill.vendor_contact || 'Contact not available'}
                                  </Typography>
                                </Grid>
                                <Grid item xs={12} md={6}>
                                  <Typography variant="subtitle2" gutterBottom>
                                    Document Details
                                  </Typography>
                                  <Typography variant="body2">
                                    Type: {bill.document_type || 'N/A'}
                                  </Typography>
                                  <Typography variant="body2">
                                    Currency: {bill.currency || 'USD'}
                                  </Typography>
                                  <Typography variant="body2">
                                    Payment Terms: {bill.payment_terms || 'N/A'}
                                  </Typography>
                                </Grid>
                              </Grid>

                              {/* Transactions Table */}
                              <Table size="small">
                                <TableHead>
                                  <TableRow>
                                    <TableCell>Description</TableCell>
                                    <TableCell>Category</TableCell>
                                    <TableCell align="right">Quantity</TableCell>
                                    <TableCell align="right">Unit Price</TableCell>
                                    <TableCell align="right">Total</TableCell>
                                  </TableRow>
                                </TableHead>
                                <TableBody>
                                  {bill.transactions && bill.transactions.length > 0 ? (
                                    bill.transactions.map((transaction, index) => (
                                      <TableRow key={index}>
                                        <TableCell>
                                          <Typography variant="body2">
                                            {transaction.description}
                                          </Typography>
                                          {transaction.notes && (
                                            <Typography variant="caption" color="textSecondary">
                                              {transaction.notes}
                                            </Typography>
                                          )}
                                        </TableCell>
                                        <TableCell>
                                          {transaction.category && (
                                            <Chip 
                                              label={transaction.category} 
                                              size="small" 
                                              variant="outlined"
                                            />
                                          )}
                                        </TableCell>
                                        <TableCell align="right">
                                          {transaction.quantity || '-'}
                                        </TableCell>
                                        <TableCell align="right">
                                          {transaction.unit_price ? formatCurrency(transaction.unit_price) : '-'}
                                        </TableCell>
                                        <TableCell align="right">
                                          <Typography fontWeight={500}>
                                            {formatCurrency(transaction.total_price)}
                                          </Typography>
                                        </TableCell>
                                      </TableRow>
                                    ))
                                  ) : (
                                    <TableRow>
                                      <TableCell colSpan={5} align="center">
                                        No transactions found
                                      </TableCell>
                                    </TableRow>
                                  )}
                                </TableBody>
                              </Table>
                            </Box>
                          </Collapse>
                        </TableCell>
                      </TableRow>
                    </React.Fragment>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </CardContent>
      </Card>
    </Box>
  );

  return (
    <ThemeProvider theme={theme}>
      <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh', bgcolor: 'background.default' }}>
        {/* Header */}
        <AppBar position="static" elevation={0} sx={{ bgcolor: 'background.paper', borderBottom: 1, borderColor: 'divider' }}>
          <Toolbar>
            <Typography variant="h6" component="div" sx={{ flexGrow: 1, color: 'text.primary' }}>
              FinanceFlow
            </Typography>
            
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <FormControlLabel
                control={
                  <Switch
                    checked={darkMode}
                    onChange={(e) => setDarkMode(e.target.checked)}
                    icon={<LightMode />}
                    checkedIcon={<DarkMode />}
                  />
                }
                label=""
              />
              <IconButton>
                <Badge badgeContent={4} color="primary">
                  <Notifications />
                </Badge>
              </IconButton>
              <IconButton>
                <Settings />
              </IconButton>
            </Box>
          </Toolbar>
        </AppBar>

        {/* Navigation Tabs */}
        <Box sx={{ borderBottom: 1, borderColor: 'divider', bgcolor: 'background.paper' }}>
          <Tabs value={currentTab} onChange={(e, newValue) => setCurrentTab(newValue)}>
            <Tab icon={<Dashboard />} label="Dashboard" />
            <Tab icon={<Receipt />} label="Bills" />
            <Tab icon={<Analytics />} label="Analytics" />
          </Tabs>
        </Box>

        {/* Main Content */}
        <Box sx={{ flexGrow: 1, p: 3 }}>
          {currentTab === 0 && <DashboardView />}
          {currentTab === 1 && <BillsView />}
          {currentTab === 2 && (
            <Box>
              {/* Analytics Header */}
              <Card sx={{ mb: 3 }}>
                <CardContent>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 2 }}>
                    <Typography variant="h5" gutterBottom>
                      Analytics & Reports
                    </Typography>
                    <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
                      <Button 
                        startIcon={<GetApp />} 
                        variant="contained"
                        onClick={downloadCSV}
                        disabled={bills.length === 0}
                      >
                        Export Bills Summary
                      </Button>
                      <Button 
                        startIcon={<GetApp />} 
                        variant="outlined"
                        onClick={downloadTransactionsCSV}
                        disabled={bills.length === 0}
                      >
                        Export Detailed Transactions
                      </Button>
                    </Box>
                  </Box>
                </CardContent>
              </Card>

              {/* Analytics Overview */}
              <Grid container spacing={3} sx={{ mb: 4 }}>
                <Grid item xs={12} md={6}>
                  <Card>
                    <CardContent>
                      <Typography variant="h6" gutterBottom>
                        Expense Summary
                      </Typography>
                      <List>
                        <ListItem>
                          <ListItemText
                            primary="Total Bills Processed"
                            secondary={metrics.totalBills}
                          />
                          <Typography variant="h6">
                            {metrics.totalBills}
                          </Typography>
                        </ListItem>
                        <ListItem>
                          <ListItemText
                            primary="Total Amount Spent"
                            secondary="All time expenses"
                          />
                          <Typography variant="h6" color="primary">
                            {formatCurrency(metrics.totalAmount)}
                          </Typography>
                        </ListItem>
                        <ListItem>
                          <ListItemText
                            primary="This Month"
                            secondary={`${metrics.thisMonthBills} bills processed`}
                          />
                          <Typography variant="h6" color="success.main">
                            {formatCurrency(metrics.monthlyAmount)}
                          </Typography>
                        </ListItem>
                        <ListItem>
                          <ListItemText
                            primary="Average Bill Amount"
                            secondary="Per transaction"
                          />
                          <Typography variant="h6">
                            {formatCurrency(metrics.totalAmount / (metrics.totalBills || 1))}
                          </Typography>
                        </ListItem>
                      </List>
                    </CardContent>
                  </Card>
                </Grid>

                <Grid item xs={12} md={6}>
                  <Card>
                    <CardContent>
                      <Typography variant="h6" gutterBottom>
                        Top Vendors by Amount
                      </Typography>
                      <List>
                        {Object.entries(metrics.vendorDistribution)
                          .sort(([,a], [,b]) => b - a)
                          .slice(0, 5)
                          .map(([vendor, amount], index) => (
                            <ListItem key={vendor}>
                              <ListItemIcon>
                                <Avatar sx={{ bgcolor: 'primary.main', width: 32, height: 32 }}>
                                  {index + 1}
                                </Avatar>
                              </ListItemIcon>
                              <ListItemText
                                primary={vendor}
                                secondary={`Total spent`}
                              />
                              <Typography variant="body1" fontWeight={500}>
                                {formatCurrency(amount)}
                              </Typography>
                            </ListItem>
                          ))}
                      </List>
                    </CardContent>
                  </Card>
                </Grid>
              </Grid>

              {/* Charts Section */}
              <Grid container spacing={3} sx={{ mb: 4 }}>
                <Grid item xs={12} md={8}>
                  <Card>
                    <CardContent>
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                        <Typography variant="h6">
                          Monthly Expense Trends
                        </Typography>
                        <Button 
                          startIcon={<BarChart />} 
                          size="small" 
                          variant="outlined"
                        >
                          View Details
                        </Button>
                      </Box>
                      <Box sx={{ height: 300 }}>
                        <Line 
                          data={monthlyTrendData} 
                          options={{
                            responsive: true,
                            maintainAspectRatio: false,
                            plugins: {
                              legend: {
                                display: false,
                              },
                              tooltip: {
                                mode: 'index',
                                intersect: false,
                              },
                            },
                            scales: {
                              x: {
                                display: true,
                                title: {
                                  display: true,
                                  text: 'Month'
                                }
                              },
                              y: {
                                display: true,
                                title: {
                                  display: true,
                                  text: 'Amount ($)'
                                },
                                beginAtZero: true,
                              },
                            },
                          }}
                        />
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>

                <Grid item xs={12} md={4}>
                  <Card>
                    <CardContent>
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                        <Typography variant="h6">
                          Vendor Distribution
                        </Typography>
                        <Button 
                          startIcon={<PieChart />} 
                          size="small" 
                          variant="outlined"
                        >
                          Breakdown
                        </Button>
                      </Box>
                      <Box sx={{ height: 300 }}>
                        <Doughnut 
                          data={chartData}
                          options={{
                            responsive: true,
                            maintainAspectRatio: false,
                            plugins: {
                              legend: {
                                position: 'bottom',
                                labels: {
                                  boxWidth: 12,
                                  padding: 10,
                                }
                              },
                              tooltip: {
                                callbacks: {
                                  label: function(context) {
                                    const label = context.label || '';
                                    const value = formatCurrency(context.parsed);
                                    return `${label}: ${value}`;
                                  }
                                }
                              },
                            },
                          }}
                        />
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>
              </Grid>

              {/* Export Options */}
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Export Options
                  </Typography>
                  <Typography variant="body2" color="textSecondary" sx={{ mb: 3 }}>
                    Download your financial data in various formats for reporting and analysis.
                  </Typography>
                  
                  <Grid container spacing={2}>
                    <Grid item xs={12} sm={6} md={4}>
                      <Card variant="outlined">
                        <CardContent>
                          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                            <Avatar sx={{ bgcolor: 'primary.main', mr: 2 }}>
                              <Receipt />
                            </Avatar>
                            <Typography variant="h6">Bills Summary</Typography>
                          </Box>
                          <Typography variant="body2" color="textSecondary" sx={{ mb: 2 }}>
                            Export all bills with vendor details, amounts, and document information.
                          </Typography>
                          <Button 
                            fullWidth 
                            variant="contained" 
                            startIcon={<GetApp />}
                            onClick={downloadCSV}
                            disabled={bills.length === 0}
                          >
                            Download CSV
                          </Button>
                        </CardContent>
                      </Card>
                    </Grid>

                    <Grid item xs={12} sm={6} md={4}>
                      <Card variant="outlined">
                        <CardContent>
                          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                            <Avatar sx={{ bgcolor: 'success.main', mr: 2 }}>
                              <Timeline />
                            </Avatar>
                            <Typography variant="h6">Detailed Transactions</Typography>
                          </Box>
                          <Typography variant="body2" color="textSecondary" sx={{ mb: 2 }}>
                            Export line-by-line transaction details with categories and notes.
                          </Typography>
                          <Button 
                            fullWidth 
                            variant="contained" 
                            startIcon={<GetApp />}
                            onClick={downloadTransactionsCSV}
                            disabled={bills.length === 0}
                          >
                            Download CSV
                          </Button>
                        </CardContent>
                      </Card>
                    </Grid>

                    <Grid item xs={12} sm={6} md={4}>
                      <Card variant="outlined">
                        <CardContent>
                          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                            <Avatar sx={{ bgcolor: 'info.main', mr: 2 }}>
                              <Analytics />
                            </Avatar>
                            <Typography variant="h6">Analytics Report</Typography>
                          </Box>
                          <Typography variant="body2" color="textSecondary" sx={{ mb: 2 }}>
                            Coming soon: Comprehensive analytics with trends and insights.
                          </Typography>
                          <Button 
                            fullWidth 
                            variant="outlined" 
                            startIcon={<GetApp />}
                            disabled
                          >
                            Coming Soon
                          </Button>
                        </CardContent>
                      </Card>
                    </Grid>
                  </Grid>
                </CardContent>
              </Card>
            </Box>
          )}
        </Box>

                 {/* Delete Confirmation Dialog */}
         <Dialog
           open={openDeleteDialog}
           onClose={handleCloseDeleteDialog}
         >
           <DialogTitle>Confirm Deletion</DialogTitle>
           <DialogContent>
             <Typography>
               Are you sure you want to delete this bill from {billToDelete?.vendor}? This action cannot be undone.
             </Typography>
           </DialogContent>
           <DialogActions>
             <Button onClick={handleCloseDeleteDialog}>Cancel</Button>
             <Button onClick={handleConfirmDelete} color="error" variant="contained">
               Delete
             </Button>
           </DialogActions>
         </Dialog>

         {/* Snackbar */}
         <Snackbar
           open={snackbar.open}
           autoHideDuration={6000}
           onClose={handleSnackbarClose}
         >
           <Alert onClose={handleSnackbarClose} severity={snackbar.severity} sx={{ width: '100%' }}>
             {snackbar.message}
           </Alert>
         </Snackbar>
       </Box>
     </ThemeProvider>
   );
}

export default App;
