WITH RECURSIVE SupplyChain (s_suppkey, s_name, s_address, level) AS (
    SELECT s_suppkey, s_name, s_address, 1
    FROM supplier
    WHERE s_acctbal > 0
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, sc.level + 1
    FROM supplier s
    JOIN SupplyChain sc ON s.s_suppkey = sc.s_suppkey
    WHERE sc.level < 5
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '2 years'
),
TotalSales AS (
    SELECT li.l_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sale,
           COUNT(DISTINCT li.l_partkey) AS part_count
    FROM lineitem li
    GROUP BY li.l_orderkey
),
SupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail
    FROM partsupp ps
    GROUP BY ps.ps_partkey HAVING SUM(ps.ps_availqty) > 500
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT n.n_name AS nation_name, 
       r.r_name AS region_name,
       SUM(ts.total_sale) AS total_sales,
       AVG(cs.c_acctbal) AS avg_customer_balance,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       MAX(sc.level) AS max_supply_chain_level
FROM TotalSales ts
JOIN RecentOrders o ON ts.l_orderkey = o.o_orderkey
JOIN customer cs ON o.o_custkey = cs.c_custkey
LEFT JOIN NationRegion n ON cs.c_nationkey = n.n_nationkey
LEFT JOIN SupplyChain sc ON cs.c_nationkey = sc.s_suppkey
WHERE n.n_name IS NOT NULL
  AND o.o_totalprice > 1000
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY total_sales DESC NULLS LAST
LIMIT 5;
