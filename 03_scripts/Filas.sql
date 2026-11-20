USE DataWarehouse;
GO

-- Conteo de filas en Capa Bronze
SELECT 'bronze.crm_cust_info' AS tabla, COUNT(*) AS filas FROM bronze.crm_cust_info
UNION ALL SELECT 'bronze.crm_prd_info', COUNT(*) FROM bronze.crm_prd_info
UNION ALL SELECT 'bronze.crm_sales_details', COUNT(*) FROM bronze.crm_sales_details
UNION ALL SELECT 'bronze.erp_cust_az12', COUNT(*) FROM bronze.erp_cust_az12
UNION ALL SELECT 'bronze.erp_loc_a101', COUNT(*) FROM bronze.erp_loc_a101
UNION ALL SELECT 'bronze.erp_px_cat_g1v2', COUNT(*) FROM bronze.erp_px_cat_g1v2;

-- Conteo de filas en Capa Silver
SELECT 'silver.crm_cust_info' AS tabla, COUNT(*) AS filas FROM silver.crm_cust_info
UNION ALL SELECT 'silver.crm_prd_info', COUNT(*) FROM silver.crm_prd_info
UNION ALL SELECT 'silver.crm_sales_details', COUNT(*) FROM silver.crm_sales_details
UNION ALL SELECT 'silver.erp_cust_az12', COUNT(*) FROM silver.erp_cust_az12
UNION ALL SELECT 'silver.erp_loc_a101', COUNT(*) FROM silver.erp_loc_a101
UNION ALL SELECT 'silver.erp_px_cat_g1v2', COUNT(*) FROM silver.erp_px_cat_g1v2;