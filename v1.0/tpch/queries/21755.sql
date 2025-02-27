WITH RECURSIVE SupplierRank AS (
    SELECT s_suppkey, s_name, s_acctbal, ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank
    FROM supplier
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, 
           COUNT(DISTINCT c.c_custkey) AS customer_count,
           SUM(CASE WHEN o.o_orderstatus = 'O' THEN 1 ELSE 0 END) AS open_orders,
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN customer c ON s.s_suppkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY n.n_nationkey, n.n_name
),
PartSupplierSummary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
ComplexQuery AS (
    SELECT p.p_partkey, p.p_name, ps.total_available, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank,
           CASE WHEN ps.supplier_count > 5 THEN 'High Supply' ELSE 'Low Supply' END AS supply_category
    FROM part p
    JOIN PartSupplierSummary ps ON p.p_partkey = ps.ps_partkey
)
SELECT ns.n_name, ns.customer_count, ns.open_orders, ns.total_orders, 
       cq.p_name, cq.total_available, cq.p_retailprice, cq.price_rank, 
       ns.total_revenue, 
       COALESCE(NULLIF(cq.supply_category, 'Low Supply'), 'Unknown') AS final_supply_category
FROM NationSummary ns
JOIN ComplexQuery cq ON ns.n_nationkey = (SELECT n_nationkey FROM supplier s WHERE s.s_suppkey = (SELECT MIN(s_suppkey) FROM SupplierRank WHERE rank = 1))
WHERE ns.total_revenue IS NOT NULL AND ns.customer_count > 0
ORDER BY ns.customer_count DESC, cq.price_rank;
