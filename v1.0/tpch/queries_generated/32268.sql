WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_availqty > 100)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= '2023-01-01'
    GROUP BY c.c_custkey, c.c_name
),
part_supplier_details AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost) AS total_supply_cost, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
)
SELECT 
    nh.n_name AS nation_name,
    sh.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(li.l_quantity) AS total_quantity,
    SUM(li.l_extendedprice) AS total_revenue,
    CASE 
        WHEN SUM(li.l_discount) > 0 THEN 'Discounted'
        ELSE 'Regular'
    END AS pricing_type,
    cs.total_spent AS customer_spending,
    psd.total_supply_cost AS total_cost,
    psd.supplier_count AS unique_suppliers,
    RANK() OVER (PARTITION BY nh.n_name ORDER BY SUM(li.l_extendedprice) DESC) AS rank_within_nation
FROM lineitem li
JOIN part p ON li.l_partkey = p.p_partkey
JOIN partsupp ps ON li.l_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation nh ON s.s_nationkey = nh.n_nationkey
LEFT JOIN customer_order_summary cs ON cs.c_custkey = li.l_orderkey
JOIN part_supplier_details psd ON p.p_partkey = psd.p_partkey
JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE li.l_shipdate BETWEEN '2023-03-01' AND '2023-09-01'
GROUP BY nh.n_name, sh.s_name, p.p_name, cs.total_spent, psd.total_supply_cost, psd.supplier_count
HAVING SUM(li.l_quantity) > 100
ORDER BY rank_within_nation, total_revenue DESC;
