WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
),
part_supplier_info AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, ps.ps_availqty
)
SELECT 
    c.c_name,
    c.c_acctbal,
    cs.total_spent,
    po.p_name,
    po.total_supplycost,
    COALESCE(r.order_rank, 0) AS recent_order_rank,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
FROM 
    customer_summary cs
JOIN 
    customer c ON cs.c_custkey = c.c_custkey
LEFT JOIN 
    ranked_orders r ON c.c_custkey = r.o_orderkey
JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
JOIN 
    part_supplier_info po ON po.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey))
WHERE 
    cs.order_count > 1
GROUP BY 
    c.c_name, c.c_acctbal, cs.total_spent, po.p_name, po.total_supplycost, r.order_rank
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_lineitem_value DESC;
