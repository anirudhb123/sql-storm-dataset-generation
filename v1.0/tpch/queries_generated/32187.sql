WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartSupplierStats AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey
),
RegionSales AS (
    SELECT 
        r.r_regionkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS region_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY r.r_regionkey
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_mfgr,
    COALESCE(ss.supplier_count, 0) AS supplier_count,
    COALESCE(ss.total_quantity, 0) AS total_quantity,
    COALESCE(cs.total_spent, 0) AS total_spent,
    COALESCE(rs.region_sales, 0) AS region_sales
FROM part p
LEFT JOIN PartSupplierStats ss ON p.p_partkey = ss.ps_partkey
LEFT JOIN CustomerOrderStats cs ON cs.c_custkey IN (SELECT c.c_custkey FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey WHERE o.o_orderdate >= '2022-01-01')
LEFT JOIN RegionSales rs ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps JOIN supplier s ON ps.ps_suppkey = s.s_suppkey WHERE s.s_acctbal > 5000)
WHERE p.p_size BETWEEN 10 AND 30
ORDER BY region_sales DESC, supplier_count DESC;
