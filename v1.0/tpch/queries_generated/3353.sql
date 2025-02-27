WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
TotalSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_availqty) > 1000
)
SELECT 
    n.n_name AS supplier_nation,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COALESCE(SUM(ts.total_revenue), 0) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names_sold
FROM 
    supplier s
LEFT JOIN 
    TopSuppliers ts ON s.s_suppkey = ts.ps_suppkey
LEFT JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_name IS NOT NULL
    AND s.s_acctbal IS NOT NULL
GROUP BY 
    n.n_name
HAVING 
    AVG(s.s_acctbal) > 500.00
ORDER BY 
    total_revenue DESC NULLS LAST;
