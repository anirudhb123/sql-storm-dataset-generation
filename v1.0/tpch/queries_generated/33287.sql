WITH RECURSIVE customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
part_supplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
order_details AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.total_spent,
    COALESCE(p.total_available, 0) AS available_parts,
    od.net_revenue,
    od.last_ship_date
FROM 
    customer_orders co
LEFT JOIN 
    part_supplier p ON p.supplier_rank = 1
LEFT JOIN 
    order_details od ON co.custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = od.l_orderkey)
WHERE 
    co.total_spent > (SELECT AVG(total_spent) FROM customer_orders)
ORDER BY 
    co.total_spent DESC
FETCH FIRST 10 ROWS ONLY;
