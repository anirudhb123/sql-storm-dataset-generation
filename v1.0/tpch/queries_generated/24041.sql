WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        DENSE_RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) as supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderdate,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Final'
            WHEN o.o_orderstatus IS NULL THEN 'Unknown'
            ELSE 'Pending'
        END AS order_status
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        OR o.o_orderdate IS NULL
),
SupplierPerformance AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        COUNT(DISTINCT fo.o_orderkey) AS order_count,
        AVG(fo.o_orderdate - DATE '2023-01-01') AS avg_days_since_order
    FROM 
        RankedSuppliers rs 
    LEFT JOIN 
        lineitem li ON rs.s_suppkey = li.l_suppkey
    LEFT JOIN 
        FilteredOrders fo ON li.l_orderkey = fo.o_orderkey
    GROUP BY 
        rs.s_suppkey, rs.s_name
)
SELECT 
    sp.s_suppkey,
    sp.s_name,
    sp.order_count,
    sp.avg_days_since_order,
    CASE 
        WHEN sp.order_count IS NULL THEN 'No Orders'
        WHEN sp.order_count < 10 THEN 'Low Activity'
        ELSE 'Active Supplier'
    END AS supplier_activity_status
FROM 
    SupplierPerformance sp
WHERE 
    sp.avg_days_since_order IS NOT NULL 
    AND sp.avg_days_since_order < 100
ORDER BY 
    sp.order_count DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY
UNION ALL
SELECT 
    -1 AS s_suppkey,
    'N/A' AS s_name,
    COUNT(*) AS order_count,
    NULL AS avg_days_since_order,
    'Aggregate Supplier' AS supplier_activity_status
FROM 
    FilteredOrders fo
WHERE 
    fo.o_orderkey IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM lineitem li WHERE li.l_orderkey = fo.o_orderkey)
ORDER BY 
    order_count
OFFSET 5 ROWS;
