WITH CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, 
           CONCAT(c.c_name, ' - ', REPLACE(c.c_address, ' ', '_')) AS cust_info,
           CASE 
               WHEN c.c_acctbal < 1000 THEN 'Low'
               WHEN c.c_acctbal BETWEEN 1000 AND 5000 THEN 'Medium'
               ELSE 'High'
           END AS account_level
    FROM customer c
),
RegionSummary AS (
    SELECT r.r_regionkey, r.r_name,
           COUNT(DISTINCT n.n_nationkey) AS nation_count,
           STRING_AGG(DISTINCT n.n_name, ', ') AS nation_names
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_custkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_linenumber) AS lineitem_count,
           MAX(o.o_orderdate) AS latest_order_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT cd.cust_info, rs.r_name, 
       od.total_revenue, od.lineitem_count, 
       od.latest_order_date, 
       cd.account_level
FROM CustomerDetails cd
JOIN orders o ON cd.c_custkey = o.o_custkey
JOIN RegionSummary rs ON cd.c_custkey IN (
    SELECT s.s_nationkey
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r)
)
JOIN OrderDetails od ON o.o_orderkey = od.o_orderkey
WHERE od.total_revenue > 1000
ORDER BY od.total_revenue DESC;
