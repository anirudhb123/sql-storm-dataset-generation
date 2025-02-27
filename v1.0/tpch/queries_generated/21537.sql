WITH RecursiveCte AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > (SELECT AVG(ps2.ps_availqty) FROM partsupp ps2 WHERE ps2.ps_partkey = p.p_partkey)
),
Aggregated AS (
    SELECT 
        r.r_name,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            ELSE 'Pending'
        END AS order_status,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS status_order
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
)
SELECT 
    DISTINCT r.r_name AS region_name,
    p.p_name AS part_name,
    rc.s_name AS supplier_name,
    fo.order_status,
    fo.o_totalprice - COALESCE(a.total_supply_cost, 0) AS adjusted_price
FROM 
    RecursiveCte rc
LEFT JOIN 
    Aggregated a ON rc.s_name = a.unique_suppliers
FULL OUTER JOIN 
    FilteredOrders fo ON rc.p_partkey = fo.o_orderkey
JOIN 
    part p ON rc.p_partkey = p.p_partkey
WHERE 
    (p.p_container IS NULL OR p.p_container LIKE 'B%')
    AND (fo.order_status = 'Finalized' OR rc.rn = 1)
ORDER BY 
    region_name, part_name, supplier_name;
