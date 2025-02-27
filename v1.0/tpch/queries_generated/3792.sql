WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT s.s_nationkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_regionkey, r.r_name
    ORDER BY 
        supplier_count DESC
    LIMIT 10
)
SELECT 
    co.c_name AS customer_name,
    rp.r_name AS region_name,
    sp.s_name AS supplier_name,
    co.order_count,
    co.total_spent,
    sp.total_supply_cost,
    RANK() OVER (PARTITION BY rp.r_name ORDER BY co.total_spent DESC) AS customer_rank,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        WHEN co.total_spent > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_segment
FROM 
    CustomerOrders co
JOIN 
    nation n ON co.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
JOIN 
    supplier sp ON n.n_nationkey = sp.s_nationkey
LEFT JOIN 
    TopRegions rp ON n.n_regionkey = rp.n_regionkey
WHERE 
    co.order_count > 5
    AND co.total_spent IS NOT NULL
ORDER BY 
    rp.r_name, co.total_spent DESC;
