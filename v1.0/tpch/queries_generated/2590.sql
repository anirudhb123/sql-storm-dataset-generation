WITH SupplierProductStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS unique_part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    n.region_name,
    s.s_name,
    COALESCE(sp.total_available_qty, 0) AS total_available_qty,
    COALESCE(sp.avg_supply_cost, 0) AS avg_supply_cost,
    COALESCE(cs.total_order_value, 0) AS total_order_value,
    COALESCE(cs.total_orders, 0) AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY n.region_name ORDER BY COALESCE(cs.total_order_value, 0) DESC) AS customer_rank
FROM 
    NationRegion n
LEFT JOIN 
    SupplierProductStats sp ON n.n_nationkey = sp.s_suppkey
LEFT JOIN 
    CustomerOrderStats cs ON n.region_name = (SELECT IFNULL(r.r_name, 'Unknown') FROM region r WHERE r.r_regionkey = (SELECT n2.n_regionkey FROM nation n2 WHERE n2.n_nationkey = cs.c_custkey))
ORDER BY 
    n.region_name, customer_rank;
