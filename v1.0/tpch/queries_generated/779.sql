WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
TotalSales AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        SUM(ts.total_sales) AS total_purchases
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        TotalSales ts ON o.o_orderkey = ts.o_orderkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    n.n_name,
    COALESCE(SUM(cp.total_purchases), 0) AS total_purchases,
    COUNT(DISTINCT s.s_suppkey) AS number_of_suppliers,
    MAX(rs.s_acctbal) AS max_supplier_balance
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    CustomerPurchases cp ON c.c_custkey = cp.c_custkey
LEFT JOIN 
    RankedSuppliers rs ON c.c_custkey = rs.s_suppkey
INNER JOIN 
    partsupp ps ON rs.s_suppkey = ps.ps_suppkey
INNER JOIN 
    part p ON ps.ps_partkey = p.p_partkey AND p.p_size > 10
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    n.n_name
ORDER BY 
    total_purchases DESC
HAVING 
    COUNT(DISTINCT rs.s_suppkey) > 5;
