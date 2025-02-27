WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'CANADA')
    WHERE sh.level < 3
),
AggregateLineItems AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_profit
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '1995-01-01' AND '1996-12-31'
    GROUP BY l.l_orderkey
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
)
SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    ph.level AS supplier_level,
    ao.total_profit,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    CASE 
        WHEN ao.total_profit IS NULL THEN 'No Profit' 
        ELSE 'Profit Exists' 
    END AS profit_status
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN SupplierHierarchy ph ON s.s_suppkey = ph.s_suppkey
LEFT JOIN AggregateLineItems ao ON ao.l_orderkey = ps.ps_partkey
LEFT JOIN customer c ON c.c_nationkey = s.s_nationkey
WHERE (p.p_size IS NOT NULL AND p.p_size > 20)
   OR (p.p_comment LIKE '%metal%' AND p.p_retailprice < 100.00)
GROUP BY p.p_partkey, p.p_name, s.s_name, ph.level, ao.total_profit
HAVING SUM(CASE WHEN c.c_acctbal < 500 THEN 1 ELSE 0 END) > 0
ORDER BY p.p_partkey, profit_status DESC;
