WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.o_custkey, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
SupplierPricing AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           p.p_name, p.p_brand, p.p_type,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
RegionNation AS (
    SELECT r.r_regionkey, r.r_name, n.n_nationkey, n.n_name
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
),
AggregateCustomerSales AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_sales
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY c.c_custkey
)
SELECT rn.r_name, rn.n_name, SUM(sp.ps_supplycost) AS total_supply_cost,
       AVG(ocs.total_sales) AS avg_customer_sales,
       ROW_NUMBER() OVER (PARTITION BY rn.r_regionkey ORDER BY SUM(sp.ps_supplycost) DESC) AS region_rank
FROM SupplierPricing sp
JOIN RegionNation rn ON sp.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_acctbal IS NOT NULL)
LEFT JOIN AggregateCustomerSales ocs ON sp.ps_partkey = ocs.c_custkey
WHERE sp.rn = 1 AND sp.ps_availqty > 0
GROUP BY rn.r_regionkey, rn.r_name, rn.n_nationkey, rn.n_name
HAVING COUNT(DISTINCT ocs.c_custkey) > 0
ORDER BY total_supply_cost DESC, avg_customer_sales DESC;
