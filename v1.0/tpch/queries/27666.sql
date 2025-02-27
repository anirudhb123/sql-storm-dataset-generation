WITH SupplierInfo AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           r.r_name AS region, 
           COUNT(DISTINCT ps.ps_partkey) AS part_count,
           SUM(ps.ps_supplycost) AS total_supply_cost,
           STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, r.r_name
    HAVING COUNT(DISTINCT ps.ps_partkey) > 5
),
OrderSummary AS (
    SELECT o.o_custkey,
           SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS total_sales,
           COUNT(DISTINCT ol.l_orderkey) AS total_orders
    FROM orders o
    JOIN lineitem ol ON o.o_orderkey = ol.l_orderkey
    GROUP BY o.o_custkey
),
CustomerInfo AS (
    SELECT c.c_custkey,
           c.c_name,
           c.c_acctbal,
           os.total_sales,
           os.total_orders
    FROM customer c
    LEFT JOIN OrderSummary os ON c.c_custkey = os.o_custkey
)
SELECT si.s_name, 
       si.region, 
       ci.c_name, 
       ci.c_acctbal, 
       ci.total_sales, 
       ci.total_orders, 
       si.part_count, 
       si.total_supply_cost,
       si.part_names
FROM SupplierInfo si
JOIN CustomerInfo ci ON si.part_count > 10
ORDER BY si.total_supply_cost DESC, ci.total_sales DESC
LIMIT 10;
