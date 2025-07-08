WITH RECURSIVE RegionCTE AS (
    SELECT r_regionkey, r_name, r_comment, 0 AS depth
    FROM region
    WHERE r_name LIKE 'A%'
    UNION ALL
    SELECT r.r_regionkey, r.r_name, r.r_comment, depth + 1
    FROM region r
    INNER JOIN RegionCTE rc ON r.r_regionkey = rc.r_regionkey
), SummarizedOrders AS (
    SELECT
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_custkey
), SupplierWithParts AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
)
SELECT 
    c.c_name AS customer_name,
    rt.r_name AS region_name,
    so.total_sales,
    sp.total_cost,
    so.order_count,
    COALESCE(sp.part_count, 0) AS available_parts,
    CASE 
        WHEN so.total_sales > 10000 THEN 'High Value'
        WHEN so.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    COALESCE((SELECT MAX(s_a.s_acctbal) 
              FROM supplier s_a 
              WHERE s_a.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = rt.r_regionkey)), 0) AS max_supplier_balance
FROM customer c
JOIN SummarizedOrders so ON c.c_custkey = so.o_custkey
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region rt ON n.n_regionkey = rt.r_regionkey
LEFT JOIN SupplierWithParts sp ON sp.ps_suppkey = so.o_custkey
WHERE so.rnk = 1
   AND (so.total_sales IS NOT NULL OR sp.total_cost IS NOT NULL)
ORDER BY so.total_sales DESC, c.c_name;
