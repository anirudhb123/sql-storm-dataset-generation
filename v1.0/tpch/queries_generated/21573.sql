WITH RECURSIVE customer_orders AS (
    SELECT c_custkey, c_name, c_acctbal, o_orderkey, o_orderdate, o_totalprice
    FROM customer
    JOIN orders ON c_custkey = o_custkey
    WHERE o_orderstatus = 'O' AND c_acctbal > 1000
    UNION ALL
    SELECT co.custkey, co.name, co.acctbal, o.orderkey, o.orderdate, o.totalprice
    FROM customer_orders co
    JOIN orders o ON co.custkey = o.o_custkey
    WHERE o.o_orderdate > co.orderdate
), aggregated_data AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT co.o_orderkey) AS total_orders,
        AVG(co.o_totalprice) AS avg_order_price
    FROM customer_orders co
    JOIN customer c ON co.c_custkey = c.c_custkey
    JOIN supplier s ON c.c_nationkey = s.s_nationkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE co.o_totalprice IS NOT NULL
    GROUP BY n.n_name
), detailed_lineitems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_value,
        MAX(l.l_discount) AS max_discount,
        COUNT(l.l_linenumber) AS line_item_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    ad.nation_name,
    ad.total_orders,
    ad.avg_order_price,
    dl.total_line_item_value,
    dl.max_discount,
    dl.line_item_count,
    CASE 
        WHEN ad.total_orders > 100 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS volume_category,
    STRING_AGG(DISTINCT CONCAT('Order:', dl.l_orderkey, ' - Value:', dl.total_line_item_value), '; ') AS order_details
FROM aggregated_data ad
LEFT OUTER JOIN detailed_lineitems dl ON ad.total_orders > 0 AND dl.l_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_custkey IN (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_acctbal < 500 OR c.c_name IS NULL
    )
)
GROUP BY ad.nation_name, ad.total_orders, ad.avg_order_price, dl.total_line_item_value, dl.max_discount, dl.line_item_count
HAVING ad.avg_order_price IS NOT NULL AND dl.total_line_item_value > 1000
ORDER BY ad.total_orders DESC, dl.max_discount DESC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
