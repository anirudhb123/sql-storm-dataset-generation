WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rnk,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'Unknown Account Balance'
            WHEN c.c_acctbal > 10000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_type
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT l.l_linenumber) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        MIN(l.l_shipdate) AS first_shipdate,
        MAX(l.l_shipdate) AS last_shipdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    n.n_name,
    r.r_name,
    COALESCE(MAX(rs.s_name), 'No Suppliers') AS top_supplier,
    SUM(od.total_sales) AS sales_summary,
    AVG(c.c_acctbal) AS avg_acctbal,
    COUNT(DISTINCT hc.c_custkey) AS customer_count,
    CASE 
        WHEN COUNT(DISTINCT hc.c_custkey) = 0 THEN 'No Customers'
        ELSE 'Customers Present'
    END AS customer_presence
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey AND rs.rnk = 1
LEFT JOIN 
    HighValueCustomers hc ON n.n_nationkey = hc.c_nationkey
JOIN 
    OrderDetails od ON hc.c_custkey = od.o_orderkey 
WHERE 
    (od.lineitem_count > 5 OR hc.customer_type = 'High Value') 
    AND n.n_name NOT LIKE '%land' 
GROUP BY 
    n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT rs.s_suppkey) > 0 
    AND SUM(od.total_sales) > 10000
ORDER BY 
    sales_summary DESC;
