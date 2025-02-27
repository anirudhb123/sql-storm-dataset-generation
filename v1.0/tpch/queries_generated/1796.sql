WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
SupplierSales AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(l.l_quantity * (1 - l.l_discount)) AS sales_value
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
TopSales AS (
    SELECT 
        ps.ps_partkey,
        SUM(ss.sales_value) AS total_sales
    FROM 
        SupplierSales ss
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ss.sales_value) > 1000
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brands,
        ns.n_name AS supplier_name,
        ps.ps_supplycost,
        COALESCE(ps.ps_availqty, 0) AS available_quantity
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        RankedSuppliers ns ON ps.ps_suppkey = ns.s_suppkey AND ns.rnk = 1
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.available_quantity,
    pd.ps_supplycost,
    ts.total_sales
FROM 
    PartDetails pd
LEFT JOIN 
    TopSales ts ON pd.p_partkey = ts.ps_partkey
WHERE 
    pd.available_quantity > 0
    AND (pd.ps_supplycost < 50 OR pd.ps_supplycost IS NULL)
ORDER BY 
    COALESCE(ts.total_sales, 0) DESC, pd.p_partkey
LIMIT 100;
