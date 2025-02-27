WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_supplycost,
          ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) as rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 5000
), 
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value,
           COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
), 
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
),
MaxSupplyCost AS (
    SELECT ps.ps_partkey, MAX(ps.ps_supplycost) AS max_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)

SELECT ns.n_name AS nation_name, rr.r_name AS region_name,
       COALESCE(sc.s_name, 'No Supplier') AS supplier_name,
       COALESCE(os.net_value, 0) AS order_net_value,
       ns.supplier_count
FROM NationRegion ns
LEFT JOIN SupplyChain sc ON ns.n_nationkey = sc.s_suppkey
LEFT JOIN OrderSummary os ON os.o_orderkey = sc.ps_partkey
JOIN MaxSupplyCost msc ON msc.ps_partkey = sc.ps_partkey
WHERE ns.supplier_count > 0
  AND os.customer_count > 5
  AND msc.max_cost > 10.00
ORDER BY ns.n_name, rr.r_name, os.net_value DESC;
