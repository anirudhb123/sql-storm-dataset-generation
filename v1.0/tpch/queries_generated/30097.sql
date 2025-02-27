WITH RECURSIVE SalesCTE AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
), HighVolumeCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(l.l_quantity) OVER (PARTITION BY c.c_custkey) AS total_quantity,
        ROW_NUMBER() OVER (ORDER BY SUM(l.l_quantity) OVER (PARTITION BY c.c_custkey) DESC) AS quantity_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate < DATE '2023-01-01'
)
SELECT 
    s.c_custkey,
    s.c_name,
    COALESCE(h.total_quantity, 0) AS total_quantity,
    s.total_sales,
    CASE 
        WHEN h.quantity_rank IS NULL THEN 'Low Volume'
        ELSE 'High Volume'
    END AS volume_category
FROM 
    SalesCTE s
LEFT JOIN 
    HighVolumeCustomers h ON s.c_custkey = h.c_custkey
WHERE 
    s.sales_rank <= 10
ORDER BY 
    s.total_sales DESC, h.total_quantity DESC;

