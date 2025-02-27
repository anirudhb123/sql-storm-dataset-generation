WITH RECURSIVE order_dates AS (
    SELECT o_orderdate,
           COUNT(o_orderkey) AS order_count
    FROM orders
    GROUP BY o_orderdate
    UNION ALL
    SELECT date_add(o_orderdate, INTERVAL 1 DAY),
           COUNT(o_orderkey)
    FROM orders
    WHERE COUNT(o_orderkey) > 0
    GROUP BY o_orderdate
),
supplier_summary AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
           AVG(s.s_acctbal) AS avg_acct_balance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
lineitem_stats AS (
    SELECT l.l_orderkey,
           COUNT(l.l_linenumber) AS lines,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    GROUP BY l.l_orderkey
),
final_stats AS (
    SELECT od.o_orderdate,
           ls.lines,
           ss.total_value,
           ss.avg_acct_balance
    FROM order_dates od
    LEFT JOIN lineitem_stats ls ON od.o_orderdate = DATE(ls.l_orderkey)
    LEFT JOIN supplier_summary ss ON ls.total_price > ss.total_value
)
SELECT f.o_orderdate,
       COALESCE(f.lines, 0) AS total_lines,
       COALESCE(f.total_value, 0) AS supplier_total_value,
       COALESCE(f.avg_acct_balance, 0) AS avg_supplier_acct_balance
FROM final_stats f
WHERE f.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
  AND (f.total_value IS NULL OR f.total_value > 1000)
ORDER BY f.o_orderdate, f.total_lines DESC;
