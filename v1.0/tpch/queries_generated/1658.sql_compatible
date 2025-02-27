
WITH CTE_Orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
CTE_Suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CTE_Region AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
)
SELECT 
    r.region_name,
    r.nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COALESCE(SUM(o.order_revenue), 0) AS total_revenue,
    SUM(s.total_supply_cost) AS total_supply_cost,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) = 0 THEN NULL
        ELSE SUM(o.order_revenue) / COUNT(DISTINCT o.o_orderkey)
    END AS avg_order_revenue
FROM CTE_Region r
LEFT JOIN CTE_Orders o ON r.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = o.o_orderkey)
LEFT JOIN CTE_Suppliers s ON r.supplier_count = (SELECT COUNT(s.s_suppkey) FROM supplier s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = r.nation_name))
GROUP BY r.region_name, r.nation_name
ORDER BY total_orders DESC, total_revenue DESC;
