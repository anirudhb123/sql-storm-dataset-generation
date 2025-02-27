WITH SupplierAggregate AS (
    SELECT 
        s.s_nationkey, 
        SUM(ps.ps_availqty) AS total_avail_qty, 
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
RegionSupplyInfo AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COALESCE(SA.total_avail_qty, 0) AS total_avail_qty,
        COALESCE(SA.avg_supply_cost, 0) AS avg_supply_cost
    FROM 
        region r
    LEFT JOIN 
        SupplierAggregate SA ON r.r_regionkey = SA.s_nationkey
)
SELECT 
    r.r_name,
    CSI.c_custkey,
    CSI.order_count,
    CSI.total_spent,
    RSI.total_avail_qty,
    RSI.avg_supply_cost,
    CASE 
        WHEN CSI.total_spent > 1000 THEN 'High Spender'
        WHEN CSI.total_spent BETWEEN 500 AND 1000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spender_category
FROM 
    CustomerOrders CSI
JOIN 
    nation n ON n.n_nationkey = CSI.c_custkey
JOIN 
    RegionSupplyInfo RSI ON n.n_regionkey = RSI.r_regionkey
WHERE 
    CSI.order_count > 5
ORDER BY 
    RSI.avg_supply_cost DESC, 
    CSI.total_spent DESC
LIMIT 50;
