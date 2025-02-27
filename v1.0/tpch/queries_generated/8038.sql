WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        c.c_name,
        n.n_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.o_orderpriority,
        ro.c_name,
        ro.n_name
    FROM RankedOrders ro
    WHERE ro.order_rank <= 10
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN TopOrders to ON l.l_orderkey = to.o_orderkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_container,
    SUM(ps.ps_availqty) AS total_avail_qty,
    SUM(ps.total_revenue) AS total_supplier_revenue,
    AVG(ps.ps_supplycost) AS avg_supply_cost
FROM part p
JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
GROUP BY p.p_name, p.p_brand, p.p_container
ORDER BY total_supplier_revenue DESC
LIMIT 10;
