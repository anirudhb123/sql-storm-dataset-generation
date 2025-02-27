WITH RegionCosts AS (
    SELECT 
        r.r_name,
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
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey, c.c_name
),
ExtremeOrders AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent,
        co.order_count,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN co.total_spent > 10000 THEN 'High' ELSE 'Low' END ORDER BY co.total_spent DESC) AS rnk
    FROM 
        CustomerOrders co
    WHERE 
        co.total_spent IS NOT NULL
)
SELECT 
    rc.r_name,
    COUNT(eo.c_custkey) AS customer_count,
    AVG(eo.total_spent) AS avg_spent,
    MAX(eo.total_spent) AS max_spent,
    STRING_AGG(eo.c_name, ', ') AS customer_names
FROM 
    RegionCosts rc 
LEFT JOIN 
    ExtremeOrders eo ON eo.c_custkey IN (
        SELECT 
            DISTINCT c.c_custkey
        FROM 
            customer c 
        WHERE 
            c.c_acctbal IS NOT NULL
            AND (c.c_acctbal > 500 OR (c.c_acctbal IS NULL AND eo.total_spent > 0))
    )
WHERE 
    rc.total_supply_cost > (SELECT AVG(total_supply_cost) FROM RegionCosts)
GROUP BY 
    rc.r_name
HAVING 
    COUNT(eo.c_custkey) > 0 OR EXISTS (
        SELECT 1 FROM LineItem li 
        WHERE li.l_discount IS NULL AND li.l_returnflag = 'R'
    )
ORDER BY 
    rc.r_name;
