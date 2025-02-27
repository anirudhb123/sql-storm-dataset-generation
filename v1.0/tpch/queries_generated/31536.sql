WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    UNION ALL
    SELECT sc.s_suppkey, sc.s_name, ps.ps_partkey, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS rnk
    FROM SupplyChain sc
    JOIN partsupp ps ON sc.ps_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0 AND sc.s_suppkey <> ps.ps_suppkey
), 

CustomerRegion AS (
    SELECT c.c_custkey, c.c_name, n.n_name AS nation_name, 
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY c.c_acctbal DESC) AS region_rnk
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
)

SELECT 
    p.p_name, 
    r.r_name, 
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_sales,
    COUNT(DISTINCT coalesce(sc.s_suppkey, 'No Supplier')) AS supplier_count,
    AVG(CASE 
            WHEN l.l_discount > 0 THEN l.l_discount
            ELSE NULL 
        END) AS avg_discount
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    CustomerRegion cr ON o.o_custkey = cr.c_custkey
LEFT JOIN 
    nation n ON cr.nation_name = n.n_name
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplyChain sc ON p.p_partkey = sc.ps_partkey
WHERE 
    l.l_shipdate BETWEEN '2022-01-01' AND '2023-01-01'
    AND (o.o_orderstatus = 'F' OR o.o_orderstatus IS NULL)
GROUP BY 
    p.p_name, r.r_name
HAVING 
    total_sales > 10000
    AND COUNT(l.l_orderkey) > 5
ORDER BY 
    total_sales DESC, r.r_name ASC;
