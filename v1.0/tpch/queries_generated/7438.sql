WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        lo.l_partkey,
        lo.l_quantity,
        lo.l_extendedprice,
        lo.l_discount,
        p.p_name,
        ps.ps_supplycost
    FROM lineitem lo
    JOIN part p ON lo.l_partkey = p.p_partkey
    JOIN partsupp ps ON lo.l_partkey = ps.ps_partkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.c_name AS customer_name,
    ro.o_totalprice,
    hvs.s_name AS supplier_name,
    SUM(od.l_extendedprice * (1 - od.l_discount)) AS revenue,
    COUNT(DISTINCT od.l_partkey) AS unique_parts
FROM RankedOrders ro
JOIN OrderDetails od ON ro.o_orderkey = od.l_orderkey
JOIN HighValueSuppliers hvs ON hvs.s_suppkey = od.l_partkey
WHERE ro.order_rank <= 5
GROUP BY ro.o_orderkey, ro.o_orderdate, ro.c_name, hvs.s_name
ORDER BY ro.o_orderdate DESC, revenue DESC
LIMIT 10;
