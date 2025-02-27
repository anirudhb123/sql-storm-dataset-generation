WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        n.n_name AS customer_nation,
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, n.n_name, l.l_partkey
)
SELECT 
    os.o_orderdate,
    os.customer_name,
    os.customer_nation,
    ss.supplier_nation,
    SUM(os.total_quantity) AS total_order_quantity,
    SUM(ss.total_cost) AS total_supplier_cost
FROM 
    order_summary os
JOIN 
    supplier_summary ss ON os.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ss.s_suppkey)
GROUP BY 
    os.o_orderdate, os.customer_name, os.customer_nation, ss.supplier_nation
ORDER BY 
    os.o_orderdate DESC, total_order_quantity DESC;
