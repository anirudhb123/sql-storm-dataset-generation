
WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, o_comment, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, o.o_comment, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.level < 5
),
SupplierProfit AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS average_quantity,
        MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE NULL END) AS max_returned_quantity
    FROM lineitem l
    GROUP BY l.l_orderkey
),
CustomerRevenue AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(CASE 
                WHEN o.o_orderstatus = 'O' THEN l.total_revenue 
                ELSE 0 
            END) AS total_order_revenue
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN LineItemDetails l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
),
RegionCriticalSuppliers AS (
    SELECT 
        n.n_name AS nation_name, 
        r.r_name AS region_name,
        s.s_suppkey,
        SUM(sp.total_cost) AS region_total_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN SupplierProfit sp ON s.s_suppkey = sp.s_suppkey
    GROUP BY n.n_name, r.r_name, s.s_suppkey
)
SELECT 
    cr.c_name,
    cr.total_order_revenue,
    rcs.region_name,
    rcs.region_total_cost,
    COALESCE(oh.level, 0) AS order_level
FROM CustomerRevenue cr
LEFT JOIN RegionCriticalSuppliers rcs ON cr.c_custkey = rcs.s_suppkey
LEFT JOIN OrderHierarchy oh ON cr.c_custkey = oh.o_custkey
WHERE cr.total_order_revenue > (
        SELECT AVG(total_order_revenue)
        FROM CustomerRevenue
    )
ORDER BY cr.total_order_revenue DESC, rcs.region_total_cost ASC;
