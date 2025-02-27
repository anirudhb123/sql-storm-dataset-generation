WITH SupplierDetails AS (
    SELECT s.s_name, s.s_nationkey, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS acct_rank
    FROM supplier s
),
HighValueSuppliers AS (
    SELECT sd.s_name, sd.s_nationkey, sd.s_acctbal
    FROM SupplierDetails sd
    WHERE sd.acct_rank <= 5
),
PartCategories AS (
    SELECT p.p_type, COUNT(*) AS part_count,
           SUM(ps.ps_supplycost) AS total_supply_cost,
           GROUP_CONCAT(DISTINCT s.s_name ORDER BY s.s_name SEPARATOR ', ') AS supplier_names
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_size IN (small, medium, large)
    GROUP BY p.p_type
),
CustomerTotalOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING total_orders > 10000
)
SELECT r.r_name AS region_name, 
       n.n_name AS nation_name, 
       hvs.s_name AS supplier_name, 
       pc.p_type AS part_type, 
       pc.part_count, 
       pc.total_supply_cost, 
       cto.c_name AS customer_name, 
       cto.total_orders
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN HighValueSuppliers hvs ON n.n_nationkey = hvs.s_nationkey
JOIN PartCategories pc ON hvs.s_name IN (SELECT DISTINCT s.s_name FROM supplier s JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size <= 30))
JOIN CustomerTotalOrders cto ON n.n_nationkey IN (SELECT DISTINCT c.c_nationkey FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey WHERE o.o_totalprice > 5000)
ORDER BY r.r_name, n.n_name, pc.p_type;
