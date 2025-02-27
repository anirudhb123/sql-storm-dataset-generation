WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        SUM(l.l_discount) AS total_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
Revenues AS (
    SELECT 
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year,
        SUM(o.revenue) AS total_revenue,
        AVG(o.total_discount) AS average_discount
    FROM OrderDetails o
    GROUP BY EXTRACT(YEAR FROM o.o_orderdate)
)
SELECT 
    r.r_name AS region_name,
    SUM(s.total_supply_value) AS total_supply_value,
    r.r_comment,
    rev.order_year,
    rev.total_revenue,
    rev.average_discount
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
JOIN Revenues rev ON rev.order_year = EXTRACT(YEAR FROM CURRENT_DATE) - 1
GROUP BY r.r_name, r.r_comment, rev.order_year, rev.total_revenue, rev.average_discount
ORDER BY total_supply_value DESC, rev.total_revenue DESC;
