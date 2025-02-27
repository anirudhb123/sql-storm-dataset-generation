WITH RECURSIVE customer_order_summary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderdate >= DATE '2023-01-01'
), supplier_part_details AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), part_sales_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT
    cs.c_name,
    cs.o_orderkey,
    cs.o_totalprice,
    cs.o_orderstatus,
    p.p_name,
    ps.total_available,
    ps.avg_supply_cost,
    sales.total_revenue,
    sales.total_orders
FROM
    customer_order_summary cs
LEFT JOIN
    part_sales_summary sales ON sales.p_partkey = (
        SELECT 
            l.l_partkey 
        FROM 
            lineitem l 
        JOIN 
            orders o ON l.l_orderkey = o.o_orderkey 
        WHERE 
            o.o_orderkey = cs.o_orderkey 
        LIMIT 1
    )
LEFT JOIN 
    supplier_part_details ps ON ps.s_suppkey = (
        SELECT 
            p.ps_suppkey 
        FROM 
            partsupp p 
        JOIN 
            lineitem l ON p.ps_partkey = l.l_partkey 
        WHERE 
            l.l_orderkey = cs.o_orderkey 
        LIMIT 1
    )
WHERE 
    cs.order_rank = 1
ORDER BY 
    cs.o_orderdate DESC, sales.total_revenue DESC;
