WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.level * 500
),
OrderPrices AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_name
),
MaxSales AS (
    SELECT nation_name, sales, RANK() OVER (ORDER BY sales DESC) AS sales_rank
    FROM RegionalSales
)
SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    ss.total_availqty,
    ss.avg_supplycost,
    ms.nation_name,
    ms.sales,
    (SELECT COUNT(DISTINCT o.o_orderkey)
     FROM orders o
     JOIN lineitem l ON o.o_orderkey = l.l_orderkey
     WHERE l.l_partkey = p.p_partkey) AS order_count,
    COALESCE(sh.level, -1) AS supplier_level
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN SupplierStats ss ON ps.ps_partkey = ss.ps_partkey
LEFT JOIN MaxSales ms ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = ms.nation_name)
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE p.p_size > 10 AND p.p_retailprice IS NOT NULL
ORDER BY p.p_partkey, ms.sales DESC
LIMIT 100;
