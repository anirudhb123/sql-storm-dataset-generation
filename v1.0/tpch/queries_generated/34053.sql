WITH RECURSIVE top_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
    ORDER BY 
        total_cost DESC
    LIMIT 10
), customer_orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 500
    GROUP BY 
        c.c_custkey, c.c_name
), order_details AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, l.l_partkey
)
SELECT 
    co.c_name,
    co.order_count,
    co.total_spent,
    od.o_orderkey,
    od.o_orderdate,
    od.net_price,
    ts.s_name AS top_supplier
FROM 
    customer_orders co
LEFT JOIN 
    order_details od ON co.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = od.o_orderkey)
LEFT JOIN 
    top_suppliers ts ON od.l_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey LIMIT 1)
WHERE 
    co.order_count > 5
AND 
    od.net_price IS NOT NULL
ORDER BY 
    co.total_spent DESC, od.o_orderdate DESC
OFFSET 10 ROWS
FETCH NEXT 20 ROWS ONLY;
