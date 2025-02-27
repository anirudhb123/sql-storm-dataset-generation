WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_availability,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
)
SELECT 
    c.c_name,
    r.r_name AS region,
    ss.total_availability,
    ss.avg_supply_cost,
    os.order_count,
    os.total_spent,
    CASE 
        WHEN os.total_spent IS NULL THEN 'No Orders'
        WHEN os.total_spent > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_value,
    COALESCE(NULLIF(ss.total_availability, 0), 'Unavailable') AS availability_status
FROM 
    customer c
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    OrderStats os ON c.c_custkey = os.o_custkey
LEFT JOIN 
    SupplierStats ss ON c.c_custkey = ss.s_suppkey
WHERE 
    r.r_name LIKE 'N%' 
    AND ss.avg_supply_cost > (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    os.total_spent DESC NULLS LAST,
    c.c_name;
