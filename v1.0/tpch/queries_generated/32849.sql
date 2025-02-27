WITH RECURSIVE TotalPriceCTE AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
), 
SupplierAvgCTE AS (
    SELECT 
        s.s_suppkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    n.n_name, 
    SUM(tp.total_price) AS total_sales,
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN o.o_orderkey END) AS total_returns,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    (SELECT COUNT(*) FROM supplier s WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000) AS high_balance_suppliers,
    AVG(sa.avg_supply_cost) AS average_supply_cost
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    TotalPriceCTE tp ON l.l_orderkey = tp.o_orderkey 
LEFT JOIN 
    SupplierAvgCTE sa ON s.s_suppkey = sa.s_suppkey
GROUP BY 
    n.n_name
HAVING 
    SUM(tp.total_price) > 10000
ORDER BY 
    total_sales DESC;
