WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, n_comment, 0 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, n.n_comment, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_nationkey = nh.n_regionkey
), supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_acctbal, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    LEFT OUTER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_address, s.s_acctbal
    HAVING COUNT(DISTINCT ps.ps_partkey) > 0
), high_value_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_phone, c.c_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rn
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
order_details AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, l.l_returnflag, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderstatus, o.o_totalprice, l.l_returnflag
)
SELECT 
    nh.n_name AS nation_name,
    sd.s_name AS supplier_name,
    c.c_name AS customer_name,
    od.o_totalprice,
    od.net_revenue,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
    SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice ELSE 0 END) AS total_discounted_price,
    MAX(CASE WHEN l.l_shipdate IS NULL THEN 'Pending' ELSE 'Shipped' END) AS shipping_status
FROM nation_hierarchy nh
JOIN supplier_details sd ON nh.n_nationkey = sd.s_nationkey
JOIN high_value_customers c ON sd.s_nationkey = c.c_nationkey
JOIN order_details od ON c.c_custkey = od.o_orderkey
LEFT JOIN partsupp ps ON sd.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem l ON od.o_orderkey = l.l_orderkey
WHERE nh.level < 3 AND (sd.part_count > 5 OR c.c_acctbal > 5000)
GROUP BY nh.n_name, sd.s_name, c.c_name, od.o_totalprice
HAVING SUM(CASE WHEN l.l_returnflag = 'Y' THEN 1 ELSE 0 END) < 2
ORDER BY nation_name, supplier_name;
