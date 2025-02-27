WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),
CustomerRegions AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        r.r_name AS region_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, r.r_name
),
AggregateLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS item_count
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '1995-01-01' AND '1995-12-31'
    GROUP BY l.l_orderkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING AVG(ps.ps_supplycost) < (SELECT AVG(ps.ps_supplycost) FROM partsupp ps)
),
OrderWithLineItem AS (
    SELECT 
        o.o_orderkey,
        COALESCE(l.l_quantity, 0) AS l_quantity,
        COALESCE(l.l_extendedprice, 0) AS l_extendedprice,
        MAX(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS has_returned_items
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    cr.region_name,
    COUNT(DISTINCT cr.c_custkey) AS total_customers,
    SUM(ols.l_quantity) AS total_quantity,
    SUM(ols.l_extendedprice) AS total_extended_price,
    SUM(CASE WHEN s_s.avg_supply_cost IS NOT NULL THEN s_s.avg_supply_cost ELSE 0 END) AS avg_supplier_cost,
    SUM(CASE WHEN s_s.total_avail_qty IS NOT NULL THEN s_s.total_avail_qty ELSE 0 END) AS total_supplier_availability
FROM CustomerRegions cr
LEFT JOIN AggregateLineItems als ON cr.c_custkey = als.l_orderkey
LEFT JOIN SupplierStats s_s ON 1=1
JOIN OrderWithLineItem ols ON cr.order_count > 5
WHERE cr.order_count > 0 AND cr.region_name IS NOT NULL AND cr.region_name NOT LIKE '%-%'
GROUP BY cr.region_name
HAVING COUNT(*) > (SELECT COUNT(DISTINCT c.c_custkey) * 0.1 FROM customer c)
ORDER BY total_quantity DESC
LIMIT 10 OFFSET 3;
