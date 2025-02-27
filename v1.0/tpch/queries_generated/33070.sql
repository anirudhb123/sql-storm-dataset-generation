WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
), 

OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
),

CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey,
           COUNT(o.o_orderkey) AS order_count,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY COUNT(o.o_orderkey) DESC) AS nation_order_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
)

SELECT 
    p.p_name,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COALESCE(cs.order_count, 0) AS customer_order_count,
    MAX(os.total_sales) AS max_daily_sales,
    AVG(NULLIF(sh.s_acctbal, 0)) AS avg_supplier_balance
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN CustomerOrders cs ON s.s_nationkey = cs.c_nationkey
LEFT JOIN OrderSummary os ON os.o_orderkey = (
    SELECT o_orderkey
    FROM orders 
    WHERE o_orderdate = CURRENT_DATE - INTERVAL '1 day'
    ORDER BY o_totalprice DESC
    LIMIT 1
)
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE p.p_retailprice > 20.00
GROUP BY p.p_name, r.r_name, n.n_name, s.s_name, cs.order_count
ORDER BY max_daily_sales DESC, p.p_name;
