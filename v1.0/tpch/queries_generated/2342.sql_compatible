
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_nationkey = s.s_nationkey
        )
),
OrdersWithTotal AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate >= DATE '1997-01-01' 
        AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.total_amount, 
        o.item_count,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity
    FROM 
        customer c
    LEFT JOIN 
        OrdersWithTotal o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.total_amount, o.item_count
)
SELECT 
    r.r_name,
    COALESCE(SUM(co.total_amount), 0) AS total_spent,
    AVG(co.item_count) AS avg_items_per_order,
    COUNT(DISTINCT s.s_suppkey) AS active_suppliers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = n.n_nationkey
    )
WHERE 
    co.total_amount > (
        SELECT AVG(total_amount) 
        FROM OrdersWithTotal
    )
GROUP BY 
    r.r_name
HAVING 
    COUNT(co.c_custkey) > 5
ORDER BY 
    total_spent DESC;
