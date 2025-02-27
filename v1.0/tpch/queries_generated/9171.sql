WITH SupplierStats AS (
    SELECT 
        s.nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.nationkey
),
OrderStats AS (
    SELECT 
        c.c_nationkey, 
        COUNT(DISTINCT o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
PerformanceBenchmark AS (
    SELECT 
        r.r_name AS region_name,
        ns.n_name AS nation_name,
        COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
        COALESCE(ss.supplier_count, 0) AS supplier_count,
        COALESCE(os.order_count, 0) AS order_count,
        COALESCE(os.total_sales, 0) AS total_sales
    FROM 
        region r
    JOIN 
        nation ns ON r.r_regionkey = ns.n_regionkey
    LEFT JOIN 
        SupplierStats ss ON ns.n_nationkey = ss.nationkey
    LEFT JOIN 
        OrderStats os ON ns.n_nationkey = os.c_nationkey
)
SELECT 
    region_name, 
    nation_name, 
    total_supply_cost, 
    supplier_count, 
    order_count, 
    total_sales
FROM 
    PerformanceBenchmark
WHERE 
    total_sales > 50000
ORDER BY 
    total_supply_cost DESC, 
    order_count DESC;
