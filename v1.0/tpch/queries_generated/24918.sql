WITH ranked_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
region_supplier AS (
    SELECT r.r_regionkey, s.s_suppkey, s.s_name, s.s_acctbal, COUNT(ps.ps_supplycost) AS supply_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY r.r_regionkey, s.s_suppkey, s.s_name, s.s_acctbal
)
SELECT 
    r.r_name AS region_name,
    COALESCE(SUM(rsu.total_value), 0) AS total_orders_value,
    MIN(s.s_acctbal) AS min_supplier_balance,
    MAX(s.s_acctbal) AS max_supplier_balance,
    CASE 
        WHEN COUNT(r.s_suppkey) = 0 THEN NULL 
        ELSE ROUND(AVG(s.s_acctbal), 2) 
    END AS avg_supplier_balance,
    STRING_AGG(DISTINCT s.s_name || ' (SuppKey: ' || s.s_suppkey || ')', ', ') AS suppliers_list
FROM region r
LEFT JOIN (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
) AS orders_agg ON r.r_regionkey = orders_agg.o_orderkey
LEFT JOIN region_supplier rsu ON r.r_regionkey = rsu.r_regionkey
JOIN supplier s ON rsu.s_suppkey = s.s_suppkey
WHERE r.r_name NOT LIKE '%bad%'
GROUP BY r.r_regionkey, r.r_name
HAVING COUNT(s.s_suppkey) > 2 OR r.r_regionkey IS NULL
ORDER BY r.r_name DESC, total_orders_value ASC
LIMIT 10;
