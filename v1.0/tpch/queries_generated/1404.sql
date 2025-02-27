WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedSupplies AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        total_supply_value,
        ROW_NUMBER() OVER (ORDER BY total_supply_value DESC) AS rank
    FROM 
        SupplierStats s
),
FilteredOrders AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent,
        co.order_count,
        CASE 
            WHEN co.total_spent IS NULL THEN 'No Orders'
            WHEN co.total_spent < 1000 THEN 'Low Spender'
            WHEN co.total_spent BETWEEN 1000 AND 5000 THEN 'Medium Spender'
            ELSE 'High Spender'
        END AS spending_category
    FROM 
        CustomerOrders co
),
JoinResults AS (
    SELECT 
        fo.c_custkey,
        fo.c_name,
        fo.total_spent,
        fo.order_count,
        fo.spending_category,
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_value
    FROM 
        FilteredOrders fo
    LEFT JOIN 
        RankedSupplies rs ON fo.order_count > 0 AND fo.total_spent >= 1000
)
SELECT 
    j.c_custkey,
    j.c_name,
    j.total_spent,
    j.order_count,
    j.spending_category,
    j.s_suppkey,
    j.s_name,
    j.total_supply_value
FROM 
    JoinResults j
WHERE 
    j.order_count > 1 OR j.total_supply_value IS NOT NULL
ORDER BY 
    j.total_spent DESC, j.total_supply_value DESC;
