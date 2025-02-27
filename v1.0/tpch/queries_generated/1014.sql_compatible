
WITH supplier_part AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) as rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
ranked_orders AS (
    SELECT 
        co.*,
        RANK() OVER (PARTITION BY co.c_custkey ORDER BY co.total_spent DESC) as order_rank
    FROM 
        customer_orders co
)
SELECT 
    sp.s_name AS supplier_name,
    sp.p_name AS part_name,
    sp.ps_supplycost AS supply_cost,
    co.c_name AS customer_name,
    co.total_spent AS customer_total_spent,
    co.o_orderdate AS order_date
FROM 
    supplier_part sp
FULL OUTER JOIN 
    ranked_orders co ON sp.s_suppkey = 
        (SELECT ps.ps_suppkey 
         FROM partsupp ps 
         WHERE ps.ps_partkey = sp.p_partkey 
         ORDER BY ps.ps_supplycost ASC LIMIT 1)
WHERE 
    sp.rn = 1 AND (co.total_spent IS NOT NULL OR sp.ps_availqty > 0)
ORDER BY 
    supplier_name, customer_total_spent DESC;
