WITH RegionSupply AS (
    SELECT 
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
OrderLineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.region_name,
    rs.total_supply_cost,
    cos.total_order_value,
    ols.total_lineitem_value
FROM 
    RegionSupply rs
JOIN 
    CustomerOrderSummary cos ON rs.region_name = (SELECT r_name FROM region WHERE r_regionkey = cos.c_nationkey)  -- Assuming one nation per region
JOIN 
    OrderLineItemSummary ols ON ols.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = (SELECT c_custkey FROM customer WHERE c_nationkey = cos.c_nationkey))
ORDER BY 
    rs.total_supply_cost DESC, cos.total_order_value DESC;
