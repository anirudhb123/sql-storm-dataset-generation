WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, p_container, p_retailprice,
           p_comment, 0 AS level
    FROM part
    WHERE p_size < 10
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, 
           p.p_retailprice, p.p_comment, ph.level + 1
    FROM part_hierarchy ph
    JOIN part p ON ph.p_partkey = p.p_partkey
    WHERE p.p_size < 20 AND ph.level < 5
),
supplier_data AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
order_details AS (
    SELECT o.o_orderkey, o.o_orderstatus, COUNT(l.l_orderkey) AS line_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey, o.o_orderstatus
),
ranked_suppliers AS (
    SELECT s.s_name, sd.total_supply_value,
           RANK() OVER (ORDER BY sd.total_supply_value DESC) AS supply_rank
    FROM supplier_data sd
    JOIN supplier s ON sd.s_suppkey = s.s_suppkey
)
SELECT ph.p_name, ph.p_mfgr, ph.p_brand, ph.p_size, od.line_count, od.revenue,
       rs.supply_rank,
       CASE
           WHEN od.revenue IS NULL THEN 'No Revenue'
           WHEN od.revenue > 10000 THEN 'High Revenue'
           ELSE 'Low Revenue'
       END AS revenue_category
FROM part_hierarchy ph
LEFT JOIN order_details od ON ph.p_partkey = od.o_orderkey
JOIN ranked_suppliers rs ON od.line_count >= 1
WHERE rs.supply_rank <= 10 OR ph.p_container IS NULL
ORDER BY ph.p_retailprice DESC, revenue_category, supply_rank;
