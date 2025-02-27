WITH RecursiveSupplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_phone, 
           s.s_acctbal, s.s_comment, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s2.s_suppkey, s2.s_name, s2.s_address, s2.s_nationkey, s2.s_phone, 
           s2.s_acctbal, s2.s_comment, r.level + 1
    FROM supplier s2
    JOIN RecursiveSupplier r ON s2.s_nationkey = r.s_nationkey 
    WHERE s2.s_acctbal > r.s_acctbal AND r.level < 5
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate > '2022-01-01')
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS cost_rank
    FROM partsupp ps
    WHERE ps.ps_availqty > 100
),
DistinctNations AS (
    SELECT DISTINCT n.n_name, n.n_regionkey
    FROM nation n
    WHERE n.n_name LIKE 'A%'
)
SELECT 
    COALESCE(s.s_name, 'Unknown') AS supplier_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE 
            WHEN lo.l_returnflag = 'R' THEN lo.l_extendedprice * (1 - lo.l_discount) 
            ELSE 0 
        END) AS return_sum,
    AVG(l.l_quantity) AS avg_quantity,
    MAX(CASE 
            WHEN lo.l_discount < 0.1 THEN lo.l_extendedprice * (1 + lo.l_tax) 
            ELSE NULL 
        END) AS max_taxed_price
FROM 
    lineitem lo
LEFT JOIN 
    orders o ON lo.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    supplier s ON lo.l_suppkey = s.s_suppkey
JOIN 
    region r ON s.s_nationkey = r.r_regionkey
JOIN 
    SupplierParts sp ON lo.l_partkey = sp.ps_partkey AND sp.cost_rank = 1
WHERE 
    r.r_name IS NOT NULL AND 
    lo.l_shipdate >= (CURRENT_DATE - INTERVAL '365 days') AND
    EXISTS (SELECT 1 FROM RecursiveSupplier rs WHERE rs.s_nationkey = s.s_nationkey)
GROUP BY 
    s.s_name, r.r_name
HAVING 
    COUNT(lo.l_orderkey) > 5
ORDER BY 
    customer_count DESC, 
    AVG(l.l_quantity) DESC
FETCH FIRST 20 ROWS ONLY;
