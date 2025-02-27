WITH RegionStats AS (
    SELECT r.r_regionkey, 
           r.r_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
           SUM(ps.ps_availqty) AS total_available_quantity
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY r.r_regionkey, r.r_name
), 
OrderStats AS (
    SELECT c.c_nationkey, 
           SUM(o.o_totalprice) AS total_order_value, 
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
), 
SupplierOrderSummary AS (
    SELECT ps.ps_partkey, 
           ps.ps_suppkey,
           SUM(l.l_quantity) AS total_quantity_ordered,
           AVG(o.o_totalprice) AS avg_order_value
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), 
NationsRanked AS (
    SELECT n.n_nationkey, 
           n.n_name, 
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS nation_rank
    FROM nation n
    JOIN orders o ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
    GROUP BY n.n_nationkey, n.n_name
)

SELECT 
    rs.r_name, 
    rs.supplier_count, 
    rs.total_available_quantity, 
    os.total_order_value, 
    os.total_orders, 
    sos.total_quantity_ordered, 
    sos.avg_order_value, 
    nr.nation_rank
FROM RegionStats rs
LEFT JOIN OrderStats os ON rs.r_regionkey = os.c_nationkey
LEFT JOIN SupplierOrderSummary sos ON rs.total_available_quantity > COALESCE(sos.total_quantity_ordered, 0)
LEFT JOIN NationsRanked nr ON os.c_nationkey = nr.n_nationkey
WHERE rs.supplier_count > 0 
AND (os.total_order_value IS NOT NULL OR nr.nation_rank <= 10)
ORDER BY rs.r_name, nr.nation_rank DESC;
