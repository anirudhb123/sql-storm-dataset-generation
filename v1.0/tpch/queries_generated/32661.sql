WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        LAG(o.o_orderkey) OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate) AS parent_orderkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
FinalOutput AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.parent_orderkey,
        COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
        hs.total_avail_qty,
        hs.avg_supply_cost,
        hs.parts_supplied,
        ho.o_totalprice,
        ho.net_revenue
    FROM 
        OrderHierarchy o
    LEFT JOIN 
        SupplierStats hs ON hs.s_suppkey = (
            SELECT ps.ps_suppkey 
            FROM partsupp ps 
            JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
            WHERE l.l_orderkey = o.o_orderkey 
            LIMIT 1
        )
    JOIN 
        HighValueOrders ho ON o.o_orderkey = ho.o_orderkey
)
SELECT 
    fo.o_orderkey,
    fo.o_orderdate,
    fo.parent_orderkey,
    fo.supplier_name,
    fo.total_avail_qty,
    fo.avg_supply_cost,
    fo.parts_supplied,
    fo.o_totalprice,
    fo.net_revenue,
    CASE 
        WHEN fo.net_revenue IS NULL THEN 'No Revenue'
        WHEN fo.net_revenue > 50000 THEN 'High Revenue'
        ELSE 'Normal Revenue'
    END AS revenue_category
FROM 
    FinalOutput fo
WHERE 
    fo.parent_orderkey IS NOT NULL
ORDER BY 
    fo.o_orderdate DESC, fo.o_orderkey;
