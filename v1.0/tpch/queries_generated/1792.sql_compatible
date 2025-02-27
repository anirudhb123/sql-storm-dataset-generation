
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
),
part_supplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.o_orderkey,
    r.o_totalprice,
    ps.p_name,
    ps.total_available,
    co.total_spent,
    CASE 
        WHEN co.total_orders > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS customer_status
FROM 
    ranked_orders r
LEFT JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    part_supplier ps ON l.l_partkey = ps.p_partkey
LEFT JOIN 
    customer_orders co ON r.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
WHERE 
    r.order_rank <= 5 AND 
    ps.avg_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp) 
ORDER BY 
    r.o_totalprice DESC, 
    ps.total_available ASC;
