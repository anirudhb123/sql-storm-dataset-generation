WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.s_acctbal, level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
), ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
), price_summary AS (
    SELECT p.p_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
), full_report AS (
    SELECT r.r_name, 
           COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(so.o_totalprice) AS total_order_value,
           AVG(s.s_acctbal) AS avg_supplier_balance,
           MAX(ps.total_supply_cost) AS max_supply_cost
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN lineitem l ON n.n_nationkey = (SELECT s.nationkey FROM supplier s WHERE s.s_suppkey = l.l_suppkey)
    LEFT JOIN ranked_orders so ON l.l_orderkey = so.o_orderkey
    LEFT JOIN price_summary ps ON ps.p_partkey = l.l_partkey
    GROUP BY r.r_name
)
SELECT r.r_name, r.nation_count, r.total_order_value, r.avg_supplier_balance, r.max_supply_cost,
       CASE 
           WHEN r.avg_supplier_balance IS NULL THEN 'No Data'
           WHEN r.avg_supplier_balance > 1000 THEN 'Healthy'
           ELSE 'Low Balance'
       END AS supplier_health
FROM full_report r
WHERE r.total_order_value IS NOT NULL
ORDER BY r.total_order_value DESC;
