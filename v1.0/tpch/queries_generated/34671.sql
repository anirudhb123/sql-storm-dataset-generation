WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
supplier_totals AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
part_summary AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_retailprice, 
           SUM(l.l_quantity) AS total_quantity_sold,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
)
SELECT nh.n_name AS nation_name,
       c.c_name AS customer_name,
       COALESCE(p.p_name, 'N/A') AS part_name,
       pt.total_quantity_sold,
       st.total_supply_cost,
       ct.total_spent,
       CASE 
           WHEN st.total_supply_cost IS NULL THEN 'No suppliers'
           ELSE 'Suppliers available'
       END AS supplier_status
FROM nation_hierarchy nh
LEFT JOIN customer_orders ct ON nh.n_nationkey = ct.c_custkey
LEFT JOIN part_summary pt ON pt.rank <= 5
LEFT JOIN supplier_totals st ON st.total_supply_cost > 1000
WHERE ct.total_spent IS NOT NULL OR st.total_supply_cost IS NOT NULL
ORDER BY nation_name, total_spent DESC;
