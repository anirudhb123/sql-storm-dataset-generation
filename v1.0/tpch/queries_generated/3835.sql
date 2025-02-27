WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
high_value_customers AS (
    SELECT 
        cus.c_custkey,
        cus.c_name,
        cus.total_spent,
        cus.total_orders,
        cus.last_order_date
    FROM 
        customer_summary cus
    WHERE 
        cus.total_spent > 100000
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
)
SELECT 
    r.r_name,
    COUNT(n.n_nationkey) AS nation_count,
    AVG(cus.total_spent) AS average_spending,
    SUM(CASE WHEN c.last_order_date < DATE '2023-01-01' THEN 1 ELSE 0 END) AS inactive_customers,
    STRING_AGG(DISTINCT s.s_name || ' - ' || p.p_name, '; ') AS supplier_parts
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    high_value_customers c ON n.n_nationkey = c.c_custkey
LEFT JOIN 
    supplier_details s ON c.c_custkey = s.s_suppkey
GROUP BY 
    r.r_name
ORDER BY 
    nation_count DESC, average_spending DESC;
