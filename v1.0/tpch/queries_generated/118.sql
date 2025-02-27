WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER(PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as price_rank,
        c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '2023-01-01' 
      AND o.o_orderdate < '2023-12-31'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER(ORDER BY SUM(sp.avg_supply_cost * sp.total_avail_qty) DESC) AS supplier_rank
    FROM Supplier s
    JOIN SupplierParts sp ON s.s_suppkey = sp.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT 
    r.region_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT c.c_custkey) AS customer_count
FROM RankedOrders o
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN nation n ON n.n_nationkey = o.c_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN TopSuppliers ts ON ts.s_nationkey = n.n_nationkey
WHERE ts.supplier_rank <= 10
AND o.price_rank <= 5
GROUP BY r.region_name
ORDER BY total_revenue DESC;
