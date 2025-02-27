WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY o.o_orderkey) AS total_lineitem_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2021-01-01' AND '2021-12-31'
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
),
supply_analysis AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty) IS NOT NULL
),
results AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        tc.c_name,
        sa.p_name,
        sa.total_available,
        coalesce(sa.supplier_count, 0) AS supplier_count
    FROM 
        ranked_orders ro
    JOIN 
        top_customers tc ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = tc.c_custkey)
    LEFT JOIN 
        supply_analysis sa ON sa.total_available > 100
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.c_name,
    r.p_name,
    r.total_available,
    r.supplier_count,
    CASE 
        WHEN r.o_totalprice > 5000 THEN 'High Value'
        WHEN r.o_totalprice BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_value_category,
    CASE 
        WHEN r.supplier_count > 5 THEN 'Diverse Supply'
        ELSE 'Limited Supply'
    END AS supply_category
FROM 
    results r
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC
LIMIT 50;
