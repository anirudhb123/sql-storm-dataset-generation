WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5 AND s.s_acctbal IS NOT NULL
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS rn
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
),
SupplierOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS cust_rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'F' AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, c.c_nationkey
),
ProductRank AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_available,
        RANK() OVER (ORDER BY SUM(ps.ps_availqty) DESC) AS availability_rank
    FROM part p
    LEFT JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 100.00
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    ph.s_name AS supplier_name,
    pr.p_name AS product_name,
    po.total_revenue,
    CASE 
        WHEN po.total_revenue > 10000 THEN 'High Value' 
        ELSE 'Low Value' 
    END AS order_value_category,
    rh.r_name AS region_name
FROM SupplierHierarchy ph
JOIN SupplierOrders po ON ph.s_suppkey = po.o_orderkey
JOIN ProductRank pr ON po.total_revenue > 5000 AND pr.availability_rank <= 10
LEFT JOIN region rh ON ph.s_nationkey = rh.r_regionkey
WHERE po.cust_rn = 1
ORDER BY po.total_revenue DESC NULLS LAST;
