WITH SupplierCost AS (
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
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (ORDER BY sc.total_cost DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        SupplierCost sc ON s.s_suppkey = sc.s_suppkey
)
SELECT 
    n.n_nationkey,
    n.n_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS average_order_value,
    MAX(o.o_totalprice) AS max_order_value,
    COALESCE(ts.supplier_rank, 0) AS supplier_rank
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    TopSuppliers ts ON ts.s_suppkey = (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
        LIMIT 1
    )
GROUP BY 
    n.n_nationkey, n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 0
ORDER BY 
    total_orders DESC, average_order_value DESC;
