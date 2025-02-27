WITH SupplierStats AS (
    SELECT 
        s_nationkey, 
        SUM(ps_availqty) AS total_avail_qty, 
        SUM(ps_supplycost) AS total_supply_cost, 
        COUNT(DISTINCT s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s_nationkey
), 
OrderSummary AS (
    SELECT 
        o_custkey, 
        COUNT(o_orderkey) AS order_count, 
        SUM(o_totalprice) AS total_spent
    FROM 
        orders
    GROUP BY 
        o_custkey
), 
CustomerRegion AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        n.n_name AS nation_name, 
        r.r_name AS region_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cr.region_name, 
    cr.nation_name, 
    SUM(os.total_spent) AS total_region_spent, 
    AVG(ss.total_supply_cost) AS avg_supply_cost_per_nation, 
    MAX(ss.total_avail_qty) AS max_available_qty
FROM 
    CustomerRegion cr
LEFT JOIN 
    OrderSummary os ON cr.c_custkey = os.o_custkey
LEFT JOIN 
    SupplierStats ss ON cr.nation_name = (SELECT n_name FROM nation WHERE n_nationkey = ss.s_nationkey)
GROUP BY 
    cr.region_name, 
    cr.nation_name
HAVING 
    SUM(os.total_spent) > 10000 
    OR MAX(ss.total_avail_qty) IS NOT NULL
ORDER BY 
    cr.region_name, 
    total_region_spent DESC;
