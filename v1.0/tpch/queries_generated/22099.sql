WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank,
        o.o_orderpriority
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 100000
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        MAX(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS is_returned,
        MAX(l.l_shipdate) AS last_ship_date
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    s.s_name AS supplier_name,
    s.total_cost AS supplier_total_cost,
    c.c_name AS customer_name,
    c.total_spent AS customer_total_spent,
    l.net_revenue,
    l.is_returned,
    l.last_ship_date
FROM RankedOrders r
LEFT JOIN SupplierInfo s ON EXISTS (
    SELECT 1
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_suppkey IN (SELECT psz.ps_suppkey FROM partsupp psz WHERE psz.ps_availqty > 10)
    AND r.o_orderkey IN (SELECT ol.l_orderkey FROM lineitem ol WHERE ol.l_partkey = p.p_partkey)
)
JOIN HighValueCustomers c ON c.total_orders > (SELECT AVG(total_orders) FROM HighValueCustomers)
JOIN LineItemDetails l ON r.o_orderkey = l.l_orderkey
WHERE r.o_orderdate >= DATEADD(MONTH, -6, CURRENT_DATE)
ORDER BY 
    r.o_totalprice DESC,
    c.total_spent ASC,
    s.total_cost DESC
LIMIT 100
