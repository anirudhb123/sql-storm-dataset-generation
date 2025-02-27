WITH OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS item_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),

TopOrders AS (
    SELECT
        o.o_custkey,
        od.total_revenue,
        od.item_count
    FROM 
        OrderDetails od
    JOIN 
        orders o ON od.o_orderkey = o.o_orderkey
    WHERE 
        od.rn <= 10
),

SupplierSummary AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),

RegionMetrics AS (
    SELECT
        r.r_regionkey,
        SUM(ps.total_supply_cost) AS regional_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierSummary ps ON ps.ps_partkey IN (
            SELECT p.p_partkey
            FROM part p 
            WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
        )
    GROUP BY 
        r.r_regionkey
)

SELECT 
    r.r_name,
    ROUND(SUM(tm.total_revenue), 2) AS total_revenue,
    COALESCE(SUM(rm.regional_supply_cost), 0) AS regional_supply_cost,
    AVG(tm.item_count) AS average_item_count,
    COUNT(DISTINCT tm.o_custkey) AS unique_customers
FROM 
    TopOrders tm
JOIN 
    region r ON tm.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = r.r_regionkey)
LEFT JOIN 
    RegionMetrics rm ON r.r_regionkey = rm.r_regionkey
GROUP BY 
    r.r_name
HAVING 
    AVG(tm.total_revenue) IS NOT NULL AND COUNT(tm.o_custkey) > 0
ORDER BY 
    total_revenue DESC;
