WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey AND s.s_suppkey != sh.s_suppkey
),
PartStatistics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        MAX(ps.ps_supplycost) AS max_supplycost,
        MIN(ps.ps_supplycost) AS min_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
RegionSales AS (
    SELECT 
        r.r_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY r.r_name
)
SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COALESCE(ps.total_availqty, 0) AS total_availqty,
    ps.avg_supplycost,
    cs.order_count,
    cs.total_spent,
    r.total_sales,
    LOCATE('critical', c.c_comment) > 0 AS is_critical_comment
FROM SupplierHierarchy s
JOIN PartStatistics ps ON s.s_suppkey = ps.p_partkey
JOIN CustomerOrderSummary cs ON cs.c_custkey = s.s_nationkey
JOIN RegionSales r ON s.s_nationkey = r.r_name
WHERE 
    s.level < 3 AND
    (cs.order_count > 5 OR cs.total_spent > 5000)
ORDER BY ps.avg_supplycost DESC, cs.total_spent DESC;
