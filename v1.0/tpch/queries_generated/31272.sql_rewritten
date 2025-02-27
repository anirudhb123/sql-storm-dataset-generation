WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.level < 5
),
RankedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice,
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS price_rank
    FROM lineitem l
    WHERE l.l_quantity > 0
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
CustomerPurchases AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
CombinedData AS (
    SELECT oh.o_orderkey, oh.o_orderdate, 
           COALESCE(cp.total_spent, 0) AS customer_total,
           COALESCE(su.total_cost, 0) AS supplier_total,
           COALESCE(rl.price_rank, 0) AS lineitem_rank
    FROM OrderHierarchy oh
    LEFT JOIN CustomerPurchases cp ON oh.o_orderkey = cp.c_custkey
    LEFT JOIN TopSuppliers su ON su.s_suppkey = oh.o_orderkey
    LEFT JOIN RankedLineItems rl ON rl.l_orderkey = oh.o_orderkey
)
SELECT DISTINCT d.o_orderkey, d.o_orderdate, d.customer_total, 
       d.supplier_total, d.lineitem_rank
FROM CombinedData d
WHERE d.customer_total > 1000
  AND d.supplier_total IS NOT NULL
  AND d.lineitem_rank BETWEEN 1 AND 5
ORDER BY d.o_orderdate DESC;