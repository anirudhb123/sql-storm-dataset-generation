WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 10000
), 

TotalSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        l.l_orderkey
)

SELECT
    p.p_name,
    r.r_name AS region,
    SUM(ps.ps_availqty) AS total_available,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(ts.total_sales) AS max_sales,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_acctbal, ')'), '; ') AS suppliers
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    orders o ON o.o_custkey = s.s_suppkey
LEFT JOIN 
    TotalSales ts ON o.o_orderkey = ts.l_orderkey
WHERE 
    p.p_size > 10 
    AND (p.p_brand LIKE 'Brand%')
GROUP BY 
    p.p_partkey, p.p_name, r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5 
    AND SUM(ps.ps_availqty) IS NOT NULL 
    AND MAX(ts.total_sales) > 1000
ORDER BY 
    avg_supply_cost DESC, total_available ASC;