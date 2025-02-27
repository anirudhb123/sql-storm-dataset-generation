WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal, 0 AS level
    FROM customer
    WHERE c_acctbal > 1000  -- Start with affluent customers
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal < ch.c_acctbal  -- Drill down to less affluent customers in the same nation
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
           MAX(ps.ps_supplycost) AS max_cost,
           MIN(ps.ps_supplycost) AS min_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
)
SELECT
    ch.c_name,
    ch.level,
    SUM(ss.total_value) AS supplier_total_value,
    AVG(ss.max_cost) AS avg_max_cost,
    MAX(os.revenue) AS max_order_revenue,
    CASE
        WHEN MAX(os.revenue) > 5000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM CustomerHierarchy ch
LEFT JOIN SupplierStats ss ON ch.c_nationkey = ss.s_suppkey  -- Assuming a region mapping
LEFT JOIN OrderDetails os ON ch.c_custkey = os.o_orderkey
GROUP BY ch.c_name, ch.level
HAVING SUM(ss.supplier_total_value) IS NOT NULL 
ORDER BY ch.level, ch.c_name;
