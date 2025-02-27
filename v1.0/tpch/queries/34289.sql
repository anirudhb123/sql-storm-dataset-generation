WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 10000

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > 5000 AND ch.level < 5
),

SupplyDetails AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_availqty, 
           AVG(ps.ps_supplycost) AS avg_supplycost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY ps.ps_partkey
),

OrderSummary AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
)

SELECT 
    ch.c_name AS Customer_Name,
    ch.level AS Hierarchy_Level,
    rd.r_name AS Region_Name,
    sd.total_availqty,
    sd.avg_supplycost,
    os.total_revenue,
    os.item_count,
    CASE 
        WHEN os.total_revenue IS NULL THEN 'No Orders'
        ELSE 'Orders Found'
    END AS Order_Status,
    COALESCE(ch.c_acctbal, 0) AS Account_Balance
FROM CustomerHierarchy ch
LEFT JOIN nation n ON ch.c_nationkey = n.n_nationkey
LEFT JOIN region rd ON n.n_regionkey = rd.r_regionkey
LEFT JOIN SupplyDetails sd ON sd.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < 50)
LEFT JOIN OrderSummary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = ch.c_custkey)
WHERE rd.r_name IS NOT NULL
ORDER BY ch.level, os.total_revenue DESC NULLS LAST
LIMIT 100;
