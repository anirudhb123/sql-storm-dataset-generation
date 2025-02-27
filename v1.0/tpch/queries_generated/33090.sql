WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS depth
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.depth + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_nationkey = nh.n_nationkey
),
supplier_data AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2023-01-01' 
      AND l.l_shipdate <= DATE '2023-12-31'
    GROUP BY l.l_orderkey
),
order_details AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, 
           SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
           COUNT(l.l_orderkey) AS total_lineitems
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
),
summary AS (
    SELECT nh.n_name, SUM(os.total_sales) AS total_sales_by_nation,
           AVG(od.o_totalprice) AS average_order_price
    FROM nation_hierarchy nh
    JOIN lineitem_summary os ON os.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = nh.n_nationkey))
    JOIN order_details od ON od.o_orderkey = os.l_orderkey
    GROUP BY nh.n_name
)
SELECT s.s_name, s.s_acctbal, s.rank, 
       COALESCE(s.total_sales_by_nation, 0) AS sales_by_nation, 
       COALESCE(s.average_order_price, 0) AS avg_order_price
FROM supplier_data s
LEFT JOIN summary su ON s.s_name = su.n_name
WHERE s.rank <= 5
ORDER BY s.s_acctbal DESC, s.s_name ASC;
