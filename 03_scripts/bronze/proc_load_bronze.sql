USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        PRINT '================================================';
        PRINT 'Cargando Capa Bronze';
        PRINT '================================================';

        TRUNCATE TABLE bronze.crm_cust_info;
        BULK INSERT bronze.crm_cust_info
        FROM 'C:\Users\royac\OneDrive\Documentos\13-11-2026\01_datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        -- Agrega aquí el TRUNCATE TABLE + BULK INSERT de las demás tablas
        -- de source_crm y source_erp...

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