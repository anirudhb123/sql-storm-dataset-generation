WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 50000
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        DENSE_RANK() OVER (ORDER BY ro.total_revenue DESC) AS revenue_rank
    FROM 
        RecentOrders ro
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    MAX(COALESCE(s.s_acctbal, 0)) AS max_supply_cost,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    rankedSuppliers rs ON l.l_suppkey = rs.s_suppkey
LEFT JOIN 
    nation n ON rs.r_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice < 100 AND 
    (l.l_discount < 0.1 OR l.l_discount IS NULL)
GROUP BY 
    ps.ps_partkey, p.p_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5 
ORDER BY 
    total_quantity DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
