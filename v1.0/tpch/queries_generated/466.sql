WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rnk
    FROM orders o
), SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_linenumber) AS item_count
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2023-10-01'
    GROUP BY l.l_orderkey
)
SELECT 
    c.c_name,
    coalesce(od.total_orders, 0) AS total_orders,
    coalesce(od.total_spent, 0) AS total_spent,
    COALESCE(rk.rnk, 0) AS last_order_rank,
    SUM(ls.revenue) AS total_revenue,
    COUNT(DISTINCT sp.ps_partkey) AS unique_parts_supplied,
    AVG(sp.avg_supply_cost) AS average_cost,
    r.r_name AS supplier_region
FROM CustomerOrderDetails od
LEFT JOIN RankedOrders rk ON od.c_custkey = rk.o_custkey
LEFT JOIN LineItemSummary ls ON rk.o_orderkey = ls.l_orderkey
LEFT JOIN supplier s ON s.s_suppkey IN (
        SELECT sp.ps_suppkey
        FROM SupplierPartInfo sp
        WHERE sp.total_avail_qty > 0
)
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY c.c_name, rk.rnk, r.r_name
HAVING COALESCE(total_revenue, 0) > 10000 
   AND COUNT(DISTINCT od.c_custkey) > 50
ORDER BY total_revenue DESC, c.c_name;
