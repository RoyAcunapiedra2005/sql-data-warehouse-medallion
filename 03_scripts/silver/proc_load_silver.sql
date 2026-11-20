USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @start_time DATETIME2, @end_time DATETIME2, @batch_start DATETIME2, @batch_end DATETIME2;

    BEGIN TRY
        SET @batch_start = GETDATE();
        PRINT '================================================';
        PRINT 'Cargando Capa Silver';
        PRINT '================================================';

        -- ------------------------------------------------
        -- 1. silver.crm_cust_info
        -- ------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncando tabla: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;

        PRINT '>> Insertando datos en: silver.crm_cust_info';
        WITH ranked_cust AS (
            SELECT
                cst_id,
                cst_key,
                cst_firstname,
                cst_lastname,
                cst_marital_status,
                cst_gndr,
                cst_create_date,
                ROW_NUMBER() OVER (
                    PARTITION BY cst_id
                    ORDER BY cst_create_date DESC
                ) AS rn
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        )
        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            TRIM(cst_key) AS cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,
            CASE
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'n/a'
            END AS cst_marital_status,
            CASE
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                ELSE 'n/a'
            END AS cst_gndr,
            cst_create_date
        FROM ranked_cust
        WHERE rn = 1;

        SET @end_time = GETDATE();
        PRINT '>> Duración silver.crm_cust_info: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seg';

        -- ------------------------------------------------
        -- 2. silver.crm_prd_info
        -- ------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncando tabla: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;

        PRINT '>> Insertando datos en: silver.crm_prd_info';
        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(TRIM(prd_key), 1, 5), '-', '_') AS cat_id,
            SUBSTRING(TRIM(prd_key), 7, LEN(TRIM(prd_key))) AS prd_key,
            TRIM(prd_nm) AS prd_nm,
            COALESCE(prd_cost, 0) AS prd_cost,
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            CAST(
                DATEADD(
                    DAY,
                    -1,
                    LEAD(prd_start_dt) OVER (
                        PARTITION BY SUBSTRING(TRIM(prd_key), 7, LEN(TRIM(prd_key)))
                        ORDER BY prd_start_dt ASC
                    )
                ) AS DATE
            ) AS prd_end_dt
        FROM bronze.crm_prd_info
        WHERE prd_id IS NOT NULL;

        SET @end_time = GETDATE();
        PRINT '>> Duración silver.crm_prd_info: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seg';

        -- ------------------------------------------------
        -- 3. silver.crm_sales_details
        -- ------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncando tabla: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;

        PRINT '>> Insertando datos en: silver.crm_sales_details';
        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT
            TRIM(sls_ord_num) AS sls_ord_num,
            TRIM(sls_prd_key) AS sls_prd_key,
            sls_cust_id,
            CASE
                WHEN sls_order_dt = 0 OR LEN(CAST(sls_order_dt AS VARCHAR(20))) <> 8 THEN NULL
                ELSE TRY_CAST(CAST(sls_order_dt AS VARCHAR(8)) AS DATE)
            END AS sls_order_dt,
            CASE
                WHEN sls_ship_dt = 0 OR LEN(CAST(sls_ship_dt AS VARCHAR(20))) <> 8 THEN NULL
                ELSE TRY_CAST(CAST(sls_ship_dt AS VARCHAR(8)) AS DATE)
            END AS sls_ship_dt,
            CASE
                WHEN sls_due_dt = 0 OR LEN(CAST(sls_due_dt AS VARCHAR(20))) <> 8 THEN NULL
                ELSE TRY_CAST(CAST(sls_due_dt AS VARCHAR(8)) AS DATE)
            END AS sls_due_dt,
            CASE
                WHEN sls_sales IS NULL
                     OR sls_sales <= 0
                     OR (sls_price IS NOT NULL AND sls_price > 0 AND sls_quantity IS NOT NULL AND sls_sales <> sls_quantity * ABS(sls_price))
                THEN COALESCE(sls_quantity, 0) * ABS(COALESCE(sls_price, 0))
                ELSE sls_sales
            END AS sls_sales,
            sls_quantity,
            CASE
                WHEN sls_price IS NULL OR sls_price <= 0 THEN
                    CASE
                        WHEN COALESCE(sls_quantity, 0) <> 0 AND COALESCE(sls_sales, 0) > 0
                        THEN ABS(sls_sales) / ABS(sls_quantity)
                        ELSE 0
                    END
                ELSE sls_price
            END AS sls_price
        FROM bronze.crm_sales_details;

        SET @end_time = GETDATE();
        PRINT '>> Duración silver.crm_sales_details: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seg';

        -- ------------------------------------------------
        -- 4. silver.erp_cust_az12
        -- ------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncando tabla: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;

        PRINT '>> Insertando datos en: silver.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT
            CASE
                WHEN TRIM(cid) LIKE 'NAS%' THEN SUBSTRING(TRIM(cid), 4, LEN(TRIM(cid)))
                ELSE TRIM(cid)
            END AS cid,
            CASE
                WHEN bdate > CAST(GETDATE() AS DATE) THEN NULL
                ELSE bdate
            END AS bdate,
            CASE
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
                ELSE 'n/a'
            END AS gen
        FROM bronze.erp_cust_az12;

        SET @end_time = GETDATE();
        PRINT '>> Duración silver.erp_cust_az12: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seg';

        -- ------------------------------------------------
        -- 5. silver.erp_loc_a101
        -- ------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncando tabla: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;

        PRINT '>> Insertando datos en: silver.erp_loc_a101';
        INSERT INTO silver.erp_loc_a101 (
            cid,
            cntry
        )
        SELECT
            REPLACE(TRIM(cid), '-', '') AS cid,
            CASE
                WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
                WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
                ELSE TRIM(cntry)
            END AS cntry
        FROM bronze.erp_loc_a101;

        SET @end_time = GETDATE();
        PRINT '>> Duración silver.erp_loc_a101: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seg';

        -- ------------------------------------------------
        -- 6. silver.erp_px_cat_g1v2
        -- ------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncando tabla: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        PRINT '>> Insertando datos en: silver.erp_px_cat_g1v2';
        INSERT INTO silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT
            TRIM(id) AS id,
            TRIM(cat) AS cat,
            TRIM(subcat) AS subcat,
            TRIM(maintenance) AS maintenance
        FROM bronze.erp_px_cat_g1v2;

        SET @end_time = GETDATE();
        PRINT '>> Duración silver.erp_px_cat_g1v2: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seg';

        SET @batch_end = GETDATE();
        PRINT '================================================';
        PRINT 'Carga de Capa Silver completada';
        PRINT 'Duración total: ' + CAST(DATEDIFF(SECOND, @batch_start, @batch_end) AS NVARCHAR(20)) + ' seg';
        PRINT '================================================';
    END TRY
    BEGIN CATCH
        PRINT '================================================';
        PRINT 'ERROR DURANTE LA CARGA DE LA CAPA SILVER';
        PRINT 'Mensaje: ' + ERROR_MESSAGE();
        PRINT 'Número : ' + CAST(ERROR_NUMBER() AS NVARCHAR(50));
        PRINT 'Línea  : ' + CAST(ERROR_LINE() AS NVARCHAR(50));
        PRINT '================================================';
    END CATCH
END;
GO