WITH SupplierCost AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        r.r_name AS region_name,
        n.n_name AS nation_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_order_value,
        n.n_nationkey
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        c.c_custkey, n.n_nationkey
),
FilteredOrders AS (
    SELECT 
        co.c_custkey,
        co.total_order_value,
        nr.region_name,
        nr.nation_name,
        sc.total_supply_cost
    FROM 
        CustomerOrders co
    JOIN 
        NationRegion nr ON co.n_nationkey = nr.n_nationkey
    JOIN 
        SupplierCost sc ON co.n_nationkey = (SELECT n.n_nationkey FROM supplier s JOIN nation n ON s.s_nationkey = n.n_nationkey WHERE s.s_suppkey = sc.s_suppkey LIMIT 1)
    WHERE 
        co.total_order_value > 10000
)
SELECT 
    region_name,
    nation_name,
    COUNT(*) AS customer_count,
    AVG(total_order_value) AS average_order_value,
    SUM(total_supply_cost) AS total_supply_cost_sum
FROM 
    FilteredOrders
GROUP BY 
    region_name, nation_name
ORDER BY 
    region_name, nation_name;
