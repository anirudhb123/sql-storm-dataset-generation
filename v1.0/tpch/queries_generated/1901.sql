WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(sc.total_supply_cost) AS total_cost
    FROM supplier s
    JOIN SupplierCosts sc ON s.s_suppkey = sc.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(sc.total_supply_cost) > 10000
),
OrderDetails AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    MAX(ro.o_totalprice) AS max_order_price,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    COALESCE(ts.total_cost, 0) AS supplier_total_cost
FROM RankedOrders ro
JOIN customer c ON ro.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN TopSuppliers ts ON ts.s_suppkey = (
    SELECT l.l_suppkey 
    FROM lineitem l 
    WHERE l.l_orderkey = ro.o_orderkey 
    LIMIT 1
)
WHERE ro.order_rank <= 10
GROUP BY n.n_name, r.r_name, ts.total_cost
ORDER BY max_order_price DESC, total_orders ASC;
