WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
)
SELECT 
    r.r_name,
    COALESCE(SUM(ss.total_supply_cost), 0) AS total_supply_cost,
    COUNT(DISTINCT ss.s_suppkey) AS total_suppliers,
    COUNT(DISTINCT hvc.c_custkey) AS high_value_customers,
    STRING_AGG(DISTINCT CONCAT(hvc.c_name, ' (', hvc.total_spent, ')'), ', ') AS high_value_customer_details
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    HighValueCustomers hvc ON ss.total_supply_cost > 5000 AND hvc.total_spent > 10000
LEFT JOIN 
    RecentOrders ro ON ro.o_custkey = hvc.c_custkey
WHERE 
    r.r_name IS NOT NULL 
GROUP BY 
    r.r_name
ORDER BY 
    total_supply_cost DESC, r.r_name;
