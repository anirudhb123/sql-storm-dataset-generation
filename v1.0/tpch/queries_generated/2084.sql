WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent,
        COUNT(o.o_orderkey) AS number_of_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineItemAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        COUNT(*) AS line_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    coalesce(ss.total_spent, 0) AS total_spent,
    so.s_name AS supplier_name,
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    la.total_line_value,
    la.line_count,
    ra.rnk,
    CASE 
        WHEN ra.o_orderstatus = 'F' THEN 'Finished'
        WHEN ra.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Unknown Status' 
    END AS order_status
FROM RankedOrders ro
LEFT JOIN CustomerStats ss ON ro.o_orderkey = ss.c_custkey
LEFT JOIN SupplierInfo so ON ss.number_of_orders = so.total_supply_cost
LEFT JOIN LineItemAggregates la ON ro.o_orderkey = la.l_orderkey
WHERE 
    ra.rnk <= 5 
    AND ro.o_totalprice > 1000 
    AND (so.total_supply_cost IS NULL OR so.total_supply_cost < 5000)
ORDER BY total_line_value DESC, customer_name;
