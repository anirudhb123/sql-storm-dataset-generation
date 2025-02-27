WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent 
    FROM customer c 
    JOIN orders o ON c.c_custkey = o.o_custkey 
    GROUP BY c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_inventory_cost 
    FROM supplier s 
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    GROUP BY s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT l.l_partkey) AS total_parts,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
)
SELECT 
    c.c_name,
    coalesce(co.total_spent, 0) AS total_spent,
    sp.total_inventory_cost,
    COUNT(DISTINCT do.o_orderkey) AS order_count,
    AVG(do.total_value) AS avg_order_value,
    RANK() OVER (ORDER BY COALESCE(co.total_spent, 0) DESC) AS customer_rank
FROM customer c
LEFT JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN SupplierParts sp ON sp.s_name LIKE '%' || (CASE 
                                                        WHEN c.c_mktsegment = 'BUILDING' THEN 'Sup'
                                                        ELSE 'Parts' END) || '%'
LEFT JOIN OrderDetails do ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = do.o_orderkey)
GROUP BY c.c_name, co.total_spent, sp.total_inventory_cost
HAVING COUNT(DISTINCT do.o_orderkey) > 0
ORDER BY customer_rank, total_spent DESC;
