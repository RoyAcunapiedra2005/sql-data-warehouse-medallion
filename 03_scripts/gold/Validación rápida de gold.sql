USE DataWarehouse;
GO

-- 1. Conteos por vista en Gold
SELECT 'gold.dim_customers' AS vista, COUNT(*) AS filas FROM gold.dim_customers
UNION ALL SELECT 'gold.dim_products', COUNT(*) FROM gold.dim_products
UNION ALL SELECT 'gold.fact_sales', COUNT(*) FROM gold.fact_sales;

-- 2. Revisar si hay ventas sin enlazar a dimensión (NULL en llaves foráneas)
SELECT
    COUNT(*) AS total_ventas,
    SUM(CASE WHEN product_key IS NULL THEN 1 ELSE 0 END) AS sin_producto,
    SUM(CASE WHEN customer_key IS NULL THEN 1 ELSE 0 END) AS sin_cliente
FROM gold.fact_sales;

-- 3. Muestra de datos enlazados
SELECT TOP 10
    f.order_number,
    c.first_name,
    c.last_name,
    c.country,
    p.product_name,
    p.category,
    f.order_date,
    f.quantity,
    f.sales_amount
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON f.customer_key = c.customer_key
LEFT JOIN gold.dim_products p ON f.product_key = p.product_key;