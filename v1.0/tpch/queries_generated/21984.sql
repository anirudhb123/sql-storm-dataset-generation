WITH RECURSIVE nation_summary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS supplier_count, SUM(s.s_acctbal) AS total_sacctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
part_analysis AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supplycost, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_variance,
           SUM(CASE WHEN ps.ps_availqty IS NULL THEN 0 ELSE ps.ps_availqty END) AS total_available_quantity
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
    HAVING SUM(o.o_totalprice) > 10000
)
SELECT 
    ns.n_name AS nation_name,
    pa.p_name AS part_name,
    co.c_name AS customer_name,
    co.total_orders,
    pa.avg_supplycost,
    ns.total_sacctbal,
    CASE 
        WHEN pa.total_available_quantity IS NULL THEN 'No Supply' 
        ELSE 'Available' 
    END AS supply_status
FROM nation_summary ns
FULL OUTER JOIN part_analysis pa ON ns.supplier_count >= pa.supplier_variance
FULL OUTER JOIN customer_order_summary co ON ns.n_nationkey = (SELECT DISTINCT c.c_nationkey FROM customer c WHERE c.c_name = co.c_name LIMIT 1)
WHERE ns.total_sacctbal IS NOT NULL
ORDER BY ns.n_name DESC, co.total_order_value ASC
FETCH FIRST 100 ROWS ONLY;
