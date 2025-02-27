WITH supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk_acctbal,
           (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS part_count 
    FROM supplier s
),
nation_info AS (
    SELECT n.n_nationkey, n.n_name,
           (SELECT COUNT(DISTINCT c.c_custkey) FROM customer c WHERE c.c_nationkey = n.n_nationkey) AS cust_count 
    FROM nation n
),
filtered_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice,
           LEAD(o.o_totalprice) OVER (ORDER BY o.o_orderdate) AS next_order_price
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 
          (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = 'O')
)
SELECT n.n_name AS nation_name, 
       COALESCE(SUM(CASE WHEN li.l_returnflag = 'R' THEN li.l_extendedprice END), 0) AS total_returned_price,
       COALESCE(SUM(CASE WHEN li.l_returnflag = 'N' AND lf.l_shipmode = 'TRUCK' THEN li.l_extendedprice END), 0) AS total_shipped_truck,
       COUNT(DISTINCT si.s_suppkey) AS total_suppliers,
       AVG(o.o_totalprice) AS avg_order_price,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       COUNT(DISTINCT ci.cust_count) FILTER (WHERE si.rnk_acctbal < 5) AS top_nation_customers
FROM nation_info n
LEFT JOIN supplier_info si ON n.n_nationkey = si.s_nationkey
LEFT JOIN filtered_orders o ON o.o_custkey = si.s_suppkey 
LEFT JOIN lineitem li ON o.o_orderkey = li.l_orderkey
LEFT JOIN (
    SELECT DISTINCT s_nationkey, s_acctbal 
    FROM supplier 
    WHERE s_acctbal IS NOT NULL
) lf ON si.s_suppkey = lf.s_nationkey
GROUP BY n.n_name
HAVING SUM(CASE WHEN si.part_count = 0 THEN 1 ELSE 0 END) > 0
ORDER BY total_returned_price DESC, avg_order_price DESC;
