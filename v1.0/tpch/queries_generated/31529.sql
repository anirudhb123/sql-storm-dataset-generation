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
PartRevenue AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey
),
HighRevenueParts AS (
    SELECT p_partkey
    FROM PartRevenue
    WHERE total_revenue > 100000
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY s.s_suppkey, s.s_name, r.r_name
),
RankedSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.r_name,
        sd.total_cost,
        ROW_NUMBER() OVER (PARTITION BY sd.r_name ORDER BY sd.total_cost DESC) AS rank
    FROM SupplierDetails sd
)
SELECT 
    rh.s_name AS supplier_name,
    rh.r_name AS region_name,
    COALESCE(p.p_name, 'Unknown Part') AS part_name,
    total_revenue,
    rank
FROM (
    SELECT 
        s.s_name,
        n.r_name,
        p.p_name,
        pr.total_revenue,
        RANK() OVER (PARTITION BY s.s_suppkey ORDER BY pr.total_revenue DESC) AS revenue_rank
    FROM SupplierHierarchy sh
    JOIN supplier s ON s.s_suppkey = sh.s_suppkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN PartRevenue pr ON p.p_partkey = pr.p_partkey
    WHERE s.s_acctbal > 5000 AND p.p_partkey IN (SELECT p_partkey FROM HighRevenueParts)
) rh
JOIN RankedSuppliers rs ON rh.s_name = rs.s_name AND rh.r_name = rs.r_name
WHERE rs.rank <= 10
ORDER BY rh.r_name, revenue_rank;
