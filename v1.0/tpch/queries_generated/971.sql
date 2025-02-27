WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_line_value,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(l.l_distinct_part) AS distinct_parts
    FROM 
        lineitem l
    JOIN (
        SELECT DISTINCT l_orderkey, l_partkey FROM lineitem
    ) AS distinct_lines ON l.l_orderkey = distinct_lines.l_orderkey
    GROUP BY 
        l.l_orderkey
)
SELECT 
    c.c_name,
    cs.total_orders,
    cs.total_spent,
    cs.avg_order_value,
    COALESCE(rs.s_name, 'No Supplier') AS top_supplier,
    COALESCE(rs.s_acctbal, 0) AS top_supplier_acctbal,
    lis.total_quantity,
    lis.net_line_value
FROM 
    CustomerOrderStats cs
JOIN 
    customer c ON cs.c_custkey = c.c_custkey
LEFT JOIN 
    RankedSuppliers rs ON cs.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_shipdate >= '2023-01-01'))
LEFT JOIN 
    LineItemStats lis ON cs.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o WHERE o.o_orderkey = lis.l_orderkey)
WHERE 
    cs.total_spent > 1000 
    AND cs.avg_order_value BETWEEN 200 AND 500
ORDER BY 
    cs.total_spent DESC;
