WITH RankedSupplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), 
AggregateLineItem AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '1995-01-01' 
    GROUP BY l.l_orderkey
), 
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, a.total_revenue,
           CASE WHEN o.o_orderstatus = 'F' THEN 'Finalized'
                ELSE 'Open' END AS order_status_desc
    FROM orders o
    LEFT JOIN AggregateLineItem a ON o.o_orderkey = a.l_orderkey
    WHERE o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
)

SELECT r.r_name, COUNT(DISTINCT f.o_orderkey) AS fulfilled_orders,
       COALESCE(ROUND(AVG(f.total_revenue), 2), 0) AS avg_revenue,
       STRING_AGG(DISTINCT s.s_name, ', ') FILTER (WHERE s.rank_acctbal <= 3) AS top_suppliers
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN FilteredOrders f ON s.s_suppkey = f.o_orderkey
GROUP BY r.r_name
HAVING COUNT(DISTINCT f.o_orderkey) > (SELECT COUNT(*) FROM orders)*0.10
   AND COALESCE(AVG(f.total_revenue), 0) > 10000
ORDER BY avg_revenue DESC NULLS LAST;
