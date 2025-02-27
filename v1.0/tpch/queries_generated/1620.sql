WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT s.s_nationkey, s.s_name, s.total_supplycost
    FROM RankedSuppliers s
    WHERE s.rnk <= 5
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spend_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
SupplierOrderDetails AS (
    SELECT 
        l.l_orderkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM lineitem l
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    GROUP BY l.l_orderkey, s.s_name
)
SELECT 
    cust.c_name AS customer_name,
    cust.order_count,
    cust.total_spent,
    COALESCE(sup.s_name, 'No Supplier') AS supplier_name,
    COALESCE(sup.total_supplycost, 0) AS supplier_total_supplycost,
    s_order.total_line_value
FROM CustomerOrderStats cust
LEFT JOIN TopSuppliers sup ON cust.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderStats)
LEFT JOIN SupplierOrderDetails s_order ON sup.s_name = s_order.s_name
WHERE cust.spend_rank <= 10
ORDER BY cust.total_spent DESC, supplier_name;
