WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
), 
TopSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name,
        n.n_name AS nation_name,
        rs.s_acctbal
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    WHERE rs.rank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
OrderLineItems AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)

SELECT 
    cs.c_name, 
    cs.total_spent,
    ts.s_name AS top_supplier_name,
    ts.s_acctbal AS supplier_acctbal,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        WHEN cs.total_spent > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_segment,
    COALESCE((
        SELECT MAX(oli.total_line_item_value)
        FROM OrderLineItems oli 
        WHERE oli.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
    ), 0) AS max_order_value
FROM CustomerOrders cs
LEFT JOIN TopSuppliers ts ON cs.c_custkey = ts.s_suppkey
WHERE cs.total_spent > COALESCE((SELECT AVG(total_spent) FROM CustomerOrders), 0)
ORDER BY cs.total_spent DESC;
