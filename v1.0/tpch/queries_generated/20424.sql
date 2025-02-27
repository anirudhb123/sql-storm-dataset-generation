WITH RECURSIVE part_supplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, 
           ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rnk
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
),
nation_summary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
           SUM(s.s_acctbal) AS total_acctbal,
           STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
filtered_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           CASE 
               WHEN o.o_orderstatus = 'O' THEN 'Open'
               WHEN o.o_orderstatus = 'F' THEN 'Filled'
               ELSE 'Unknown'
           END AS order_status
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
)
SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
       n.n_name AS nation_name, ns.supplier_count, 
       ns.total_acctbal, ns.supplier_names, 
       fo.o_orderkey, fo.o_totalprice, fo.o_orderdate, fo.order_status
FROM part_supplier ps
FULL OUTER JOIN nation_summary ns ON ps.ps_suppkey = ns.n_nationkey
LEFT JOIN filtered_orders fo ON fo.o_orderkey = (SELECT MIN(o_orderkey) 
                                                  FROM orders 
                                                  WHERE o_orderdate > fo.o_orderdate)
WHERE ps.rnk = 1
OR (ns.supplier_count IS NULL AND ns.supplier_names IS NOT NULL)
ORDER BY ps.ps_partkey, fo.o_totalprice DESC NULLS LAST;
