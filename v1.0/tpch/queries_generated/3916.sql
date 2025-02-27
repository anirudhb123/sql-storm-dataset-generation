WITH RankedOrders AS (
    SELECT 
        o.orderkey,
        o.totalprice,
        o.orderdate,
        RANK() OVER (PARTITION BY DATE_TRUNC('month', o.orderdate) ORDER BY o.totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.orderstatus = 'O'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS total_parts
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
),
TopSuppliers AS (
    SELECT 
        sd.s_name,
        sd.s_acctbal,
        sd.total_parts
    FROM SupplierDetails sd
    WHERE sd.total_parts > (
        SELECT AVG(total_parts) FROM SupplierDetails
    )
)
SELECT 
    co.c_name,
    co.total_spent,
    rs.orderkey,
    rs.totalprice,
    CASE 
        WHEN rs.order_rank <= 5 THEN 'Top Order'
        ELSE 'Regular Order'
    END AS order_classification,
    ts.s_name AS top_supplier_name,
    ts.s_acctbal AS top_supplier_balance
FROM CustomerOrders co
JOIN RankedOrders rs ON co.total_spent = rs.totalprice
FULL OUTER JOIN TopSuppliers ts ON ts.total_parts > 3
WHERE co.c_custkey IS NOT NULL 
   AND ts.s_acctbal IS NOT NULL
   AND COALESCE(ts.s_acctbal, 0) < 100000;
