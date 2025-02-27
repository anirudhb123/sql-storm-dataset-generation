WITH SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), DetailedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey, 
        l.l_suppkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        SUM(l.l_quantity) AS total_quantity
    FROM lineitem l
    GROUP BY l.l_orderkey, l.l_partkey, l.l_suppkey
)
SELECT 
    sp.s_name AS supplier_name,
    co.c_name AS customer_name,
    dl.l_orderkey,
    dl.l_partkey,
    dl.total_line_value,
    dl.total_quantity,
    sp.total_parts,
    sp.total_value,
    co.total_orders,
    co.total_spent
FROM SupplierParts sp
JOIN DetailedLineItems dl ON sp.s_suppkey = dl.l_suppkey
JOIN CustomerOrders co ON co.total_orders > 0
WHERE sp.total_value > 10000
ORDER BY sp.s_name, co.c_name, dl.l_orderkey;
