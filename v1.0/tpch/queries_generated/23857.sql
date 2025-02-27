WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderdate >= '2022-01-01'
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_discount,
        l.l_returnflag,
        l.l_linestatus,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS line_rank
    FROM lineitem l
)
SELECT 
    COALESCE(co.c_custkey, 0) AS customer_key,
    COUNT(DISTINCT ro.o_orderkey) AS orders_count,
    SUM(ld.l_extendedprice * (1 - ld.l_discount)) AS total_revenue,
    MAX(hs.total_supply_cost) AS highest_supplier_cost
FROM RankedOrders ro
FULL OUTER JOIN CustomerOrders co ON ro.o_orderkey = co.total_orders
LEFT JOIN LineItemDetails ld ON ro.o_orderkey = ld.l_orderkey
LEFT JOIN HighValueSuppliers hs ON ld.l_partkey = hs.s_suppkey
WHERE 
    co.total_spent IS NULL OR 
    (ld.l_returnflag = 'R' AND ld.l_linestatus = 'O')
GROUP BY co.c_custkey
HAVING 
    SUM(ld.l_quantity) OVER (PARTITION BY co.c_custkey) > 10
    AND COUNT(ro.o_orderkey) > 0
ORDER BY customer_key DESC;
