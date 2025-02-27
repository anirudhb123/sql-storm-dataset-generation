WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_custkey = ch.c_custkey
    WHERE c.c_acctbal > ch.c_acctbal
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING COUNT(n.n_nationkey) > 5
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey
)
SELECT 
    p.p_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    SUM(ps.ps_availqty) AS total_available,
    AVG(CASE WHEN cl.level IS NOT NULL THEN cl.c_acctbal END) AS avg_account_balance,
    COUNT(DISTINCT os.o_orderkey) AS total_orders,
    rg.r_name AS region_name,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000 THEN 'High Value' 
        ELSE 'Standard Value' 
    END AS sales_category
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN CustomerHierarchy cl ON cl.c_custkey = s.s_nationkey
LEFT JOIN TopRegions rg ON s.s_nationkey = rg.r_regionkey
LEFT JOIN OrderSummary os ON os.o_orderkey = ps.ps_partkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
GROUP BY p.p_name, s.s_name, rg.r_name
HAVING SUM(ps.ps_availqty) > 0 AND COUNT(DISTINCT os.o_orderkey) > 10
ORDER BY sales_category DESC, total_available DESC;
