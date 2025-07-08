WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        0 AS level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        oh.level + 1
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_custkey = oh.o_orderkey)
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
)
SELECT 
    p.p_partkey,
    p.p_name,
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_revenue,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(s.s_acctbal) AS max_supplier_balance,
    CASE 
        WHEN SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) > 10000 
        THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_status,
    ARRAY_AGG(DISTINCT rd.r_name) AS regions
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region rd ON n.n_regionkey = rd.r_regionkey
WHERE 
    p.p_retailprice BETWEEN 10.00 AND 100.00
    AND (o.o_orderdate > '1996-01-01' OR o.o_orderstatus IS NULL)
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC
LIMIT 50;