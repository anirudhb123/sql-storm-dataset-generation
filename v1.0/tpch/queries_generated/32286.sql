WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_name = 'USA'
    
    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS recent_order
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
supplier_count AS (
    SELECT ps.partkey, COUNT(DISTINCT ps.s_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.partkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    COALESCE(c.c_name, 'No Customer') AS customer_name,
    COALESCE(o.o_orderkey, 0) AS order_id,
    AVG(li.l_discount) OVER (PARTITION BY p.p_partkey) AS avg_discount,
    CASE 
        WHEN s.s_acctbal IS NULL THEN 'Unknown Balance'
        ELSE CAST(s.s_acctbal AS VARCHAR)
    END AS supplier_balance,
    nh.n_name AS nation_name,
    sc.supplier_count
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN customer_orders co ON co.recent_order = 1
LEFT JOIN orders o ON co.o_orderkey = o.o_orderkey
LEFT JOIN customer c ON co.c_custkey = c.c_custkey
LEFT JOIN nation_hierarchy nh ON s.s_nationkey = nh.n_nationkey
JOIN supplier_count sc ON p.p_partkey = sc.partkey
WHERE p.p_retailprice > 20.00
AND (s.s_acctbal IS NULL OR s.s_acctbal > 500.00)
ORDER BY p.p_partkey, nation_name DESC;
