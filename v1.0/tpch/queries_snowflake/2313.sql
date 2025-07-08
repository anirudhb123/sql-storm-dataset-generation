
WITH RankedSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.discount)) DESC) AS revenue_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(r.total_revenue, 0) AS total_revenue
    FROM 
        customer c
    LEFT JOIN 
        RankedSales r ON c.c_custkey = r.c_custkey
    WHERE 
        r.revenue_rank IS NULL OR r.revenue_rank <= 10
),
SupplierMetrics AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
AggregatedData AS (
    SELECT 
        rc.n_name AS region_name,
        SUM(tc.total_revenue) AS total_region_revenue,
        MAX(sm.total_supply_cost) AS max_supply_cost,
        MIN(sm.part_count) AS min_part_count
    FROM 
        nation rc
    LEFT JOIN 
        TopCustomers tc ON rc.n_nationkey = (SELECT n.n_nationkey FROM customer c JOIN nation n ON c.c_nationkey = n.n_nationkey WHERE c.c_custkey = tc.c_custkey)
    LEFT JOIN 
        SupplierMetrics sm ON rc.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = sm.s_suppkey)
    GROUP BY 
        rc.n_name
)
SELECT 
    a.region_name,
    COALESCE(a.total_region_revenue, 0) AS total_region_revenue,
    COALESCE(a.max_supply_cost, 0) AS max_supply_cost,
    COALESCE(a.min_part_count, 0) AS min_part_count
FROM 
    AggregatedData a

UNION ALL

SELECT 
    'TOTAL' AS region_name,
    SUM(a.total_region_revenue) AS total_region_revenue,
    SUM(a.max_supply_cost) AS max_supply_cost,
    SUM(a.min_part_count) AS min_part_count
FROM 
    AggregatedData a
WHERE 
    a.total_region_revenue IS NOT NULL;
