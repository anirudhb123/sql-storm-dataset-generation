WITH RankedSales AS (
    SELECT 
        l_orderkey,
        l_partkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS rn
    FROM 
        lineitem
    WHERE 
        l_returnflag = 'N'
    GROUP BY 
        l_orderkey, l_partkey
),
CustomerAchievements AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 0
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        (SUM(ps.ps_supplycost * ps.ps_availqty) / NULLIF(SUM(ps.ps_availqty), 0)) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    r.r_name,
    SUM(total_sales) AS total_sales_by_region,
    COUNT(DISTINCT ca.c_custkey) AS customer_count,
    MAX(sp.avg_supply_cost) AS max_supply_cost,
    MIN(sp.avg_supply_cost) AS min_supply_cost
FROM 
    RankedSales rs
JOIN 
    orders o ON rs.l_orderkey = o.o_orderkey
JOIN 
    customer ca ON o.o_custkey = ca.c_custkey
JOIN 
    nation n ON ca.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    SupplierPerformance sp ON sp.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = rs.l_partkey 
        ORDER BY ps.ps_supplycost ASC 
        LIMIT 1
    )
WHERE 
    rs.rn = 1
GROUP BY 
    r.r_name
HAVING 
    AVG(sp.avg_supply_cost) IS NOT NULL
ORDER BY 
    total_sales_by_region DESC, customer_count DESC;
