WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderpriority, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01' 
      AND o.o_orderstatus = 'O'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available_quantity, 
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        sd.s_suppkey, 
        sd.s_name, 
        sd.total_available_quantity, 
        sd.avg_supply_cost,
        RANK() OVER (ORDER BY sd.total_available_quantity DESC) AS supplier_rank
    FROM SupplierDetails sd
),
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey, 
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    r.o_orderkey, 
    r.o_orderdate, 
    r.o_totalprice, 
    r.o_orderpriority, 
    ts.s_name AS top_supplier_name, 
    ts.total_available_quantity, 
    ts.avg_supply_cost, 
    c.order_count,
    CASE 
        WHEN c.order_count IS NULL THEN 'No Orders' 
        ELSE 'Has Orders' 
    END AS order_status
FROM RankedOrders r
LEFT JOIN TopSuppliers ts ON r.o_orderkey = (SELECT l.l_orderkey 
                                              FROM lineitem l 
                                              WHERE l.l_linenumber = 1 
                                              AND l.l_orderkey = r.o_orderkey)
LEFT JOIN CustomerOrderCounts c ON r.o_orderkey = c.c_custkey
WHERE r.order_rank <= 5
ORDER BY r.o_orderpriority, r.o_orderdate DESC;
