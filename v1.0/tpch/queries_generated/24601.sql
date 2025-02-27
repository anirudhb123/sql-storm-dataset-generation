WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey <> sh.s_suppkey AND sh.level < 5
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(o.o_totalprice), 0.00) AS total_order_value,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus IN ('O', 'F')
    WHERE c.c_acctbal > 1000.00
    GROUP BY c.c_custkey, c.c_name
),
TopRegions AS (
    SELECT n.n_regionkey, r.r_name, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN orders o ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
    GROUP BY n.n_regionkey, r.r_name
    HAVING COUNT(DISTINCT o.o_orderkey) > 10
),
FinalMetrics AS (
    SELECT 
        ph.p_partkey,
        ph.p_name,
        ph.supplier_count,
        ph.total_availqty,
        ph.avg_supplycost,
        co.total_order_value,
        co.total_orders,
        tr.order_count,
        ROW_NUMBER() OVER (PARTITION BY ph.p_partkey ORDER BY co.total_order_value DESC NULLS LAST) AS rank
    FROM FilteredParts ph
    LEFT JOIN CustomerOrders co ON co.total_orders > 0
    LEFT JOIN TopRegions tr ON tr.order_count IS NOT NULL
    WHERE ph.total_availqty IS NOT NULL AND ph.supplier_count > 0
)
SELECT DISTINCT 
    f.p_partkey,
    f.p_name,
    f.supplier_count,
    f.total_availqty,
    f.avg_supplycost,
    f.total_order_value,
    f.total_orders,
    f.order_count
FROM FinalMetrics f
WHERE EXISTS (SELECT 1 
              FROM SupplierHierarchy sh 
              WHERE sh.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = f.p_partkey))
ORDER BY f.total_order_value DESC, f.p_partkey
FETCH FIRST 50 ROWS ONLY;
