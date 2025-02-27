WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, p.p_brand
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS orders_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= DATE '2023-01-01'
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    c.c_name AS customer_name,
    c.total_spent,
    spd.p_brand,
    spd.total_available_quantity,
    spd.total_supply_cost
FROM RankedOrders ro
JOIN CustomerOrderSummary c ON ro.o_custkey = c.c_custkey
JOIN SupplierPartDetails spd ON spd.ps_partkey = (SELECT ps_partkey FROM partsupp ORDER BY RANDOM() LIMIT 1)
WHERE ro.order_rank <= 10
ORDER BY ro.o_orderdate DESC, ro.o_totalprice DESC;
