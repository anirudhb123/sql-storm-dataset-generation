
WITH RECURSIVE region_nation AS (
    SELECT n.n_nationkey,
           n.n_name,
           r.r_regionkey,
           r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    UNION ALL
    SELECT n.n_nationkey,
           CONCAT(n.n_name, ' & ', r.r_name) AS n_name,
           r.r_regionkey,
           CONCAT(r.r_name, ' (nested)') AS r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE n.n_nationkey < 10
),
customer_orders AS (
    SELECT c.c_custkey,
           c.c_name,
           COALESCE(SUM(o.o_totalprice), 0) AS total_spent,
           c.c_mktsegment
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
),
order_details AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_value,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    rn.n_name AS nation_name,
    c.c_name AS customer_name,
    c.total_spent,
    SUM(od.total_value) AS total_order_value,
    COALESCE(ROUND((SUM(od.total_value) / NULLIF(c.total_spent, 0)) * 100, 2), 0) AS value_to_spent_ratio,
    CASE
        WHEN c.c_mktsegment = 'BUILDING' THEN 'Commercial'
        WHEN c.c_mktsegment = 'AUTOMOBILE' THEN 'Personal'
        ELSE 'Unknown'
    END AS segment_type,
    CONCAT('Customer ', c.c_name, ' has spent ', COALESCE(NULLIF(c.total_spent, 0)::TEXT, 'nothing'), ' on orders.') AS narrative
FROM customer_orders c
FULL OUTER JOIN order_details od ON c.c_custkey = od.o_orderkey
JOIN region_nation rn ON rn.n_nationkey = c.c_custkey % 5
WHERE c.total_spent > 1000 OR rn.r_regionkey IS NULL
GROUP BY rn.n_name, c.c_name, c.total_spent, c.c_mktsegment
HAVING COUNT(od.o_orderkey) > 0 OR SUM(od.total_value) IS NOT NULL
ORDER BY value_to_spent_ratio DESC;