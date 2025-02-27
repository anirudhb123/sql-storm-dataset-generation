WITH SupplierParts AS (
    SELECT 
        ps.s_suppkey, 
        SUM(ps.ps_availqty) AS total_avail_qty, 
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts
    FROM 
        partsupp ps
    GROUP BY 
        ps.s_suppkey
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(co.total_order_value) AS total_spent
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.o_custkey
    WHERE 
        co.order_rank <= 5
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rv.r_name, 
    SUM(sp.total_avail_qty) AS total_available,
    COUNT(DISTINCT hvc.c_custkey) AS high_value_customers,
    AVG(sp.total_avail_qty) AS avg_avail_qty_per_supplier
FROM 
    region rv
LEFT JOIN 
    nation n ON rv.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierParts sp ON s.s_suppkey = sp.s_suppkey
LEFT JOIN 
    HighValueCustomers hvc ON hvc.c_custkey = s.s_nationkey
WHERE 
    sp.total_avail_qty IS NOT NULL
GROUP BY 
    rv.r_name
ORDER BY 
    total_available DESC, high_value_customers DESC;
