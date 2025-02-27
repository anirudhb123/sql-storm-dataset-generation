WITH customer_orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS orders_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name
), supplier_parts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    GROUP BY 
        s.s_suppkey, s.s_name
), most_expensive_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice
    FROM 
        part p
    ORDER BY 
        p.p_retailprice DESC 
    LIMIT 10
)
SELECT 
    co.c_custkey, 
    co.c_name, 
    co.total_spent, 
    co.orders_count,
    sp.s_name AS supplier_name, 
    sp.total_available, 
    sp.total_cost,
    mp.p_name AS expensive_part
FROM 
    customer_orders co
JOIN 
    supplier_parts sp ON sp.total_available > 100 
JOIN 
    most_expensive_parts mp ON TRUE
WHERE 
    co.total_spent > 1000 
ORDER BY 
    co.total_spent DESC, sp.total_cost ASC;
