WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 0 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.level < 3
),
SupplierStats AS (
    SELECT s.s_suppkey, SUM(ps.ps_availqty) AS total_availqty, AVG(s.s_acctbal) AS avg_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerTotals AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
LineItemStats AS (
    SELECT l.l_partkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
           COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS total_returns
    FROM lineitem l
    GROUP BY l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(s.total_availqty, 0) AS available_quantity,
    COALESCE(cs.total_order_value, 0) AS customer_order_value,
    ls.total_revenue,
    ls.total_returns,
    DENSE_RANK() OVER (ORDER BY ls.total_revenue DESC) AS revenue_rank
FROM part p
LEFT JOIN SupplierStats s ON s.s_suppkey IN (
    SELECT DISTINCT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey = p.p_partkey AND ps.ps_availqty > 0
)
LEFT JOIN CustomerTotals cs ON cs.c_custkey IN (
    SELECT o.o_custkey 
    FROM orders o 
    WHERE o.o_orderkey IN (
        SELECT oh.o_orderkey 
        FROM OrderHierarchy oh
    )
)
CROSS JOIN LineItemStats ls
WHERE p.p_retailprice > 20.00
  AND (p.p_comment IS NULL OR p.p_comment LIKE '%special%')
ORDER BY revenue_rank, p.p_partkey;
