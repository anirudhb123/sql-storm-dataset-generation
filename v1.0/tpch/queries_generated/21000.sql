WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, CAST(s_name AS VARCHAR(100)) AS path
    FROM supplier
    WHERE s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, CONCAT(sh.path, ' -> ', s.s_name)
    FROM supplier AS s
    JOIN supplier_hierarchy AS sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal AND LENGTH(sh.path) < 200
),
lineitem_stats AS (
    SELECT l_partkey, COUNT(*) AS total_orders, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM lineitem
    GROUP BY l_partkey
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rn
    FROM part AS p
    JOIN partsupp AS ps ON p.p_partkey = ps.ps_partkey
),
national_supplier_summary AS (
    SELECT n.n_name, SUM(s.s_acctbal) AS total_balance
    FROM nation AS n
    JOIN supplier AS s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
order_stats AS (
    SELECT o.o_orderkey, 
           CASE 
               WHEN o.o_totalprice > 5000.00 THEN 'High Value' 
               WHEN o.o_totalprice BETWEEN 1000.00 AND 5000.00 THEN 'Medium Value' 
               ELSE 'Low Value' 
           END AS order_value_category,
           COUNT(l.l_orderkey) AS item_count
    FROM orders AS o
    LEFT JOIN lineitem AS l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_totalprice
),
detailed_report AS (
    SELECT 
        ps.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CASE 
            WHEN ps.ps_availqty IS NULL THEN 'Unavailable'
            ELSE 'Available'
        END AS availability_status,
        COALESCE(ls.total_orders, 0) AS total_orders_by_part,
        COALESCE(ls.total_revenue, 0) AS total_revenue_by_part,
        'Supplier: ' || sh.path AS supplier_path,
        os.order_value_category,
        os.item_count
    FROM part_supplier AS ps
    JOIN part AS p ON ps.p_partkey = p.p_partkey
    LEFT JOIN lineitem_stats AS ls ON ps.p_partkey = ls.l_partkey
    LEFT JOIN supplier_hierarchy AS sh ON ps.ps_suppkey = sh.s_suppkey
    LEFT JOIN order_stats AS os ON os.o_orderkey = ps.ps_partkey
    WHERE ps.rn = 1
)
SELECT
    d.p_partkey,
    d.p_name,
    d.availability_status,
    d.total_orders_by_part,
    d.total_revenue_by_part,
    d.supplier_path,
    n.n_name,
    ns.total_balance
FROM detailed_report AS d
JOIN national_supplier_summary AS ns ON ns.total_balance > 2000.00
JOIN nation AS n ON n.n_name = ANY(ARRAY(SELECT DISTINCT n_name FROM nation))
ORDER BY d.total_revenue_by_part DESC
LIMIT 100;
