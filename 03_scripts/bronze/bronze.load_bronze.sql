USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @start_time DATETIME2, @end_time DATETIME2, @batch_start DATETIME2, @batch_end DATETIME2;

    BEGIN TRY
        SET @batch_start = GETDATE();
        PRINT '================================================';
        PRINT 'Cargando Capa Bronze';
        PRINT '================================================';

        -- ------------------------------------------------
        -- Tablas CRM
        -- ------------------------------------------------
        PRINT '------------------------------------------------';
        PRINT 'Cargando tablas CRM';
        PRINT '------------------------------------------------';

        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze.crm_cust_info;
        BULK INSERT bronze.crm_cust_info
        FROM 'C:\Users\royac\OneDrive\Documentos\13-11-2026\01_datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Duración crm_cust_info: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seg';

        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze.crm_prd_info;
        BULK INSERT bronze.crm_prd_info
        FROM 'C:\Users\royac\OneDrive\Documentos\13-11-2026\01_datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Duración crm_prd_info: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seg';

        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze.crm_sales_details;
        BULK INSERT bronze.crm_sales_details
        FROM 'C:\Users\royac\OneDrive\Documentos\13-11-2026\01_datasets\source_crm\sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Duración crm_sales_details: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seg';

        -- ------------------------------------------------
        -- Tablas ERP
        -- ------------------------------------------------
        PRINT '------------------------------------------------';
        PRINT 'Cargando tablas ERP';
        PRINT '------------------------------------------------';

        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze.erp_cust_az12;
        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\Users\royac\OneDrive\Documentos\13-11-2026\01_datasets\source_erp\CUST_AZ12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Duración erp_cust_az12: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seg';

        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze.erp_loc_a101;
        BULK INSERT bronze.erp_loc_a101
        FROM 'C:\Users\royac\OneDrive\Documentos\13-11-2026\01_datasets\source_erp\LOC_A101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Duración erp_loc_a101: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seg';

        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'C:\Users\royac\OneDrive\Documentos\13-11-2026\01_datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Duración erp_px_cat_g1v2: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seg';

        SET @batch_end = GETDATE();
        PRINT '================================================';
        PRINT 'Carga de Capa Bronze completada';
        PRINT 'Duración total: ' + CAST(DATEDIFF(SECOND, @batch_start, @batch_end) AS NVARCHAR(20)) + ' seg';
        PRINT '================================================';
    END TRY
    BEGIN CATCH
        PRINT '================================================';
        PRINT 'ERROR DURANTE LA CARGA DE LA CAPA BRONZE';
        PRINT 'Mensaje: ' + ERROR_MESSAGE();
        PRINT 'Número : ' + CAST(ERROR_NUMBER() AS NVARCHAR(50));
        PRINT '================================================';
    END CATCH
END;
GO