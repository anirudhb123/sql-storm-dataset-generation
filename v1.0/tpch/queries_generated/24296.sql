WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(MONTH, -6, CURRENT_DATE)
    GROUP BY o.o_orderkey, o.o_custkey
),
OrderDetails AS (
    SELECT 
        ro.o_orderkey,
        ro.total_order_value,
        c.c_name,
        rs.s_name AS supplier_name,
        rs.total_supply_cost
    FROM RecentOrders ro
    LEFT JOIN customer c ON ro.o_custkey = c.c_custkey
    LEFT JOIN RankedSuppliers rs ON c.c_nationkey = rs.s_nationkey AND rs.rnk = 1
)
SELECT 
    od.o_orderkey,
    od.c_name,
    od.supplier_name,
    CASE 
        WHEN od.total_order_value IS NULL THEN 'No Value'
        ELSE CAST(od.total_order_value AS VARCHAR)
    END AS order_value,
    COALESCE(od.total_supply_cost, 0) AS supply_cost,
    CASE 
        WHEN od.total_supply_cost IS NULL THEN 'Supplier Not Found'
        WHEN od.total_supply_cost = 0 THEN 'Free Supply'
        ELSE 'Standard'
    END AS supply_status
FROM OrderDetails od
FULL OUTER JOIN region r ON r.r_regionkey = (
    SELECT n.n_regionkey
    FROM nation n
    WHERE n.n_nationkey = (
        SELECT MAX(n2.n_nationkey) 
        FROM nation n2 
        WHERE n2.n_name LIKE 'N%'
    )
)
AND od.o_orderkey IS NOT NULL
ORDER BY od.o_orderkey DESC NULLS LAST;
