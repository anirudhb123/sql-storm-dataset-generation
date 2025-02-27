WITH Recursive_Nation AS (
    SELECT n_nationkey, n_name, n_regionkey, n_comment,
           CAST(n_name AS VARCHAR(100)) AS path,
           1 AS level
    FROM nation
    WHERE n_nationkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, n.n_comment,
           CAST(CONCAT(r.path, ' -> ', n.n_name) AS VARCHAR(100)),
           r.level + 1
    FROM nation n
    JOIN Recursive_Nation r ON n.n_regionkey = r.n_nationkey
    WHERE r.level < 5
), Part_Supplier AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT s.s_nationkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_retailprice IS NOT NULL AND p.p_size > 5
    GROUP BY p.p_partkey, p.p_name
), Order_Summary AS (
    SELECT o.o_orderkey, o.o_totalprice,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           COUNT(DISTINCT l.l_linenumber) AS line_count,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_totalprice
), Customer_Aggregate AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 0 AND LEFT(c.c_name, 1) IN ('A', 'B', 'C')
    GROUP BY c.c_custkey
)
SELECT n.n_name AS nation_name,
       COUNT(DISTINCT ps.p_partkey) AS part_count,
       SUM(ps.total_supply_cost) AS total_supply_cost,
       COALESCE(c.order_count, 0) AS customer_order_count,
       COALESCE(c.total_spent, 0) AS total_customer_spending,
       DENSE_RANK() OVER (ORDER BY SUM(ps.total_supply_cost) DESC) AS supply_rank,
       STRING_AGG(DISTINCT r.path, '; ') AS nation_hierarchy
FROM Recursive_Nation n
LEFT JOIN Part_Supplier ps ON n.n_nationkey = ps.p_partkey
LEFT JOIN Customer_Aggregate c ON ps.total_supply_cost > 0
GROUP BY n.n_name
HAVING COUNT(DISTINCT ps.p_partkey) > 2 OR SUM(ps.total_supply_cost) < 5000
ORDER BY nation_name ASC, supply_rank DESC;
