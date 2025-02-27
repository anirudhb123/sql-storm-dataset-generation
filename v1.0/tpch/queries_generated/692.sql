WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01' 
      AND o.o_orderdate < DATE '2024-01-01'
), SupplierPtr AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availability
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), CustomerSummary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), LineItemStats AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2023-01-01' 
      AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY l.l_orderkey
)
SELECT 
    c.c_name,
    COALESCE(cs.total_spent, 0) AS total_spent,
    COALESCE(cs.order_count, 0) AS order_count,
    COUNT(DISTINCT lo.l_orderkey) AS total_orders_in_lineitems,
    SUM(ls.total_line_revenue) AS total_line_revenue,
    MAX(sr.total_availability) AS max_avail_qty,
    AVG(CASE WHEN ro.o_orderstatus = 'O' THEN ro.o_totalprice ELSE NULL END) AS avg_open_order_price
FROM customer_summary cs
LEFT JOIN RankedOrders ro ON cs.c_custkey = ro.o_custkey
LEFT JOIN LineItemStats ls ON ro.o_orderkey = ls.l_orderkey
LEFT JOIN SupplierPtr sr ON sr.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#45') 
LEFT JOIN orders o ON cs.c_custkey = o.o_custkey
WHERE cs.total_spent > 1000.00
GROUP BY c.c_name
HAVING AVG(cs.order_count) > 5
ORDER BY total_spent DESC;
