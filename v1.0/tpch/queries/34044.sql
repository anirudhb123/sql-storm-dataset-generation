
WITH RECURSIVE RevenueCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        1 AS level
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name

    UNION ALL

    SELECT 
        r.c_custkey,
        r.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        r.level + 1
    FROM RevenueCTE r
    JOIN orders o ON o.o_custkey = r.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE r.level < 5
    GROUP BY r.c_custkey, r.c_name, r.level
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_availqty
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cr.region_name,
    cr.nation_name,
    COUNT(DISTINCT r.c_custkey) AS customer_count,
    SUM(r.total_revenue) AS total_revenue,
    SUM(ps.total_supplycost) AS total_supplycost,
    AVG(pd.p_retailprice) AS avg_part_price,
    MAX(pd.total_availqty) AS max_avail_qty
FROM CustomerRegion cr
JOIN RevenueCTE r ON cr.c_custkey = r.c_custkey
JOIN SupplierSales ps ON ps.s_suppkey IN (
    SELECT ps_inner.ps_suppkey 
    FROM partsupp ps_inner
    JOIN part p ON ps_inner.ps_partkey = p.p_partkey
    WHERE p.p_type = 'brass'
)
JOIN PartDetails pd ON pd.p_partkey IN (
    SELECT l_inner.l_partkey 
    FROM lineitem l_inner 
    JOIN orders o ON l_inner.l_orderkey = o.o_orderkey 
    WHERE o.o_orderstatus = 'F'
)
GROUP BY cr.region_name, cr.nation_name
HAVING COUNT(DISTINCT r.c_custkey) > 0
ORDER BY total_revenue DESC;
