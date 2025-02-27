WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_nationkey
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           CASE 
               WHEN o.o_totalprice > 1000 THEN 'High'
               WHEN o.o_totalprice > 500 THEN 'Medium'
               ELSE 'Low'
           END AS price_category
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
    AND o.o_orderdate BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
),
AggregateLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           COUNT(l.l_linenumber) AS item_count
    FROM lineitem l
    WHERE l.l_returnflag = 'N' 
    AND l.l_shipdate <= CURRENT_DATE
    GROUP BY l.l_orderkey
)
SELECT r.n_name, COUNT(DISTINCT fo.o_orderkey) AS order_count,
       SUM(ali.net_revenue) AS total_revenue,
       MAX(rs.total_cost) AS max_supplier_cost,
       MIN(ali.item_count) FILTER (WHERE ali.item_count > 1) AS min_item_count_with_multiple_items,
       STRING_AGG(DISTINCT CASE WHEN fo.price_category = 'High' THEN 'High Value' END, ', ') AS high_value_orders
FROM RankedSuppliers rs
JOIN FilteredOrders fo ON EXISTS (
        SELECT 1
        FROM lineitem l
        WHERE l.l_orderkey = fo.o_orderkey
        AND l.l_suppkey = rs.s_suppkey
    )
JOIN nation r ON rs.n_nationkey = r.n_nationkey
JOIN AggregateLineItems ali ON fo.o_orderkey = ali.l_orderkey
GROUP BY r.n_name
HAVING COUNT(DISTINCT fo.o_orderkey) > 5
   AND MAX(rs.total_cost) IS NOT NULL
ORDER BY total_revenue DESC NULLS LAST;
