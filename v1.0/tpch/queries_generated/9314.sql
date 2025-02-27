WITH SupplierAggregate AS (
    SELECT 
        s.n_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.n_nationkey
),
OrderDetails AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        c.c_nationkey
),
RegionSummary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(sa.total_supply_cost) AS region_supply_cost,
        SUM(od.total_order_value) AS region_order_value,
        SUM(od.order_count) AS total_orders
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        SupplierAggregate sa ON n.n_nationkey = sa.n_nationkey
    LEFT JOIN 
        OrderDetails od ON n.n_nationkey = od.c_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r.r_name,
    r.nation_count,
    COALESCE(r.region_supply_cost, 0) AS region_supply_cost,
    COALESCE(r.region_order_value, 0) AS region_order_value,
    COALESCE(r.total_orders, 0) AS total_orders
FROM 
    RegionSummary r
ORDER BY 
    r.region_order_value DESC, r.nation_count DESC;
