WITH RECURSIVE cust_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) as rn
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
), aggregated_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), max_order AS (
    SELECT 
        c.c_custkey,
        MAX(o.o_totalprice) AS max_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), part_suppliers AS (
    SELECT 
        p.p_partkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_supplycost > (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2 WHERE ps2.ps_partkey = p.p_partkey)
)
SELECT 
    co.c_name,
    COALESCE(co.order_count, 0) AS order_count,
    COALESCE(co.total_spent, 0) AS total_spent,
    mo.max_spent,
    ps.p_partkey,
    ps.s_name,
    ps.ps_availqty
FROM 
    aggregated_orders co
FULL OUTER JOIN 
    max_order mo ON co.c_custkey = mo.c_custkey
LEFT JOIN 
    part_suppliers ps ON ps.rank = 1
ORDER BY 
    co.total_spent DESC NULLS LAST, mo.max_spent DESC;
