WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE sh.level < 5 
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL AND total_spent > (SELECT AVG(o_totalprice) FROM orders)
),
part_summary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available, 
           AVG(ps.ps_supplycost) AS average_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
ranked_lineitems AS (
    SELECT l.*, 
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS item_rank,
           SUM(l.l_extendedprice) OVER (PARTITION BY l.l_orderkey) AS total_lineitem_value
    FROM lineitem l
),
top_suppliers AS (
    SELECT s.s_name, s.s_acctbal, ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
)
SELECT DISTINCT 
    p.p_name,
    cs.c_name as customer_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    (SELECT COUNT(*) FROM supplier_hierarchy) AS number_of_suppliers,
    TH.s_name as top_supplier_with_most_acctbal
FROM part_summary p
JOIN ranked_lineitems li ON p.p_partkey = li.l_partkey
JOIN customer_orders cs ON cs.order_count > 0
LEFT JOIN top_suppliers TH ON TH.rank = 1
WHERE li.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY p.p_name, cs.c_name, TH.s_name
HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
ORDER BY total_revenue DESC, p.p_name;
