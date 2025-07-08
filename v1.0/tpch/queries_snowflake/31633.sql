
WITH RECURSIVE OrderCTE AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
SupplierStats AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail_qty,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           MAX(s.s_acctbal) AS highest_account_balance,
           COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
RegionNationStats AS (
    SELECT r.r_regionkey, n.n_nationkey, COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, n.n_nationkey
)
SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.c_name,
       COALESCE(ss.total_avail_qty, 0) AS total_avail_qty,
       COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
       rn.total_suppliers AS total_suppliers,
       CASE 
           WHEN o.o_totalprice > 5000 THEN 'High Value'
           WHEN o.o_totalprice > 1000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS order_value_category
FROM OrderCTE o
LEFT JOIN SupplierStats ss ON o.o_orderkey = ss.ps_partkey
JOIN RegionNationStats rn ON rn.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_name = o.c_name LIMIT 1))
WHERE o.order_rank <= 10
ORDER BY o.o_orderdate DESC, o.o_totalprice DESC;
