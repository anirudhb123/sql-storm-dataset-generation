WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, 
           NULL AS parent_suppkey,
           CAST(1 AS INTEGER) AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal * 0.8 AS s_acctbal, s.s_comment,
           sh.s_suppkey AS parent_suppkey,
           sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE sh.level < 5 AND s.s_suppkey <> sh.s_suppkey
), 

part_statistics AS (
    SELECT p.p_partkey, SUM(COALESCE(ps.ps_availqty, 0)) AS total_avail_qty,
           AVG(p.p_retailprice) AS avg_retail_price, 
           COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),

customer_order_summary AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent,
           STRING_AGG(DISTINCT o.o_orderstatus, ', ') AS order_statuses
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND CURRENT_DATE
    GROUP BY c.c_custkey 
)

SELECT 
    ph.p_partkey,
    ph.total_avail_qty,
    ph.avg_retail_price,
    ph.unique_suppliers_count,
    cus.c_custkey,
    cus.order_count,
    cus.total_spent,
    cus.order_statuses,
    CASE 
        WHEN cus.total_spent > 1000 THEN 'High Value Customer'
        WHEN cus.total_spent IS NULL THEN 'No Orders'
        ELSE 'Regular Customer' 
    END AS customer_category
FROM part_statistics ph
CROSS JOIN customer_order_summary cus
LEFT JOIN region r ON r.r_regionkey = (SELECT DISTINCT n.n_regionkey FROM nation n WHERE n.n_nationkey = cus.c_nationkey)
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = cus.c_nationkey
WHERE (ph.avg_retail_price > (SELECT AVG(p2.p_retailprice) FROM part p2) OR ph.total_avail_qty < 50)
  AND (NULLIF(cus.total_spent, 0) IS NOT NULL OR r.r_name = 'ASIA')
ORDER BY customer_category, ph.avg_retail_price DESC, cus.total_spent ASC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
