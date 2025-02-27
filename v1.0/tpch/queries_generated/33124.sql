WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON s.s_nationkey = sh.s_nationkey AND s.s_suppkey <> sh.s_suppkey
    WHERE sh.level < 5
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= DATE '2023-01-01'
    GROUP BY c.c_custkey, c.c_name
    HAVING total_spent > (SELECT AVG(total_spent) FROM 
                          (SELECT SUM(o.o_totalprice) AS total_spent
                           FROM customer c
                           JOIN orders o ON c.c_custkey = o.o_custkey
                           GROUP BY c.c_custkey) AS avg_spending)
),
part_supplier_details AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_quantity, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING total_quantity > 0
)
SELECT rhs.cust_details, 
       part_detail.p_name,
       part_detail.total_quantity,
       rank() OVER (PARTITION BY rhs.cust_details ORDER BY part_detail.total_quantity DESC) AS quantity_rank,
       CASE 
           WHEN part_detail.avg_supply_cost IS NULL THEN 'Not Available'
           ELSE part_detail.avg_supply_cost::varchar
       END AS avg_cost_information
FROM (
    SELECT CONCAT(c.c_name, ' - ', c.c_custkey) AS cust_details
    FROM top_customers tc
    JOIN customer c ON c.c_custkey = tc.c_custkey
) rhs
CROSS JOIN part_supplier_details part_detail
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
WHERE (part_detail.total_quantity > 100 OR part_detail.avg_supply_cost IS NOT NULL)
ORDER BY rhs.cust_details, quantity_rank;
