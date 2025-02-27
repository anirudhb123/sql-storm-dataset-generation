WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
TopRegionSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name,
        r.r_name,
        RANK() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, r.r_name
),
FinalReport AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        ts.s_name AS top_supplier_name,
        ts.supplier_rank
    FROM 
        RankedOrders ro
    LEFT JOIN 
        lineitem li ON ro.o_orderkey = li.l_orderkey
    LEFT JOIN 
        SupplierParts ps ON li.l_partkey = ps.ps_partkey
    LEFT JOIN 
        TopRegionSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
    WHERE 
        ro.rn <= 5
    GROUP BY 
        ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.c_name, ts.s_name, ts.supplier_rank
)
SELECT 
    *,
    CASE 
        WHEN part_count IS NULL THEN 'No parts'
        ELSE CAST(part_count AS VARCHAR)
    END AS part_count_description,
    'Total Price: ' || CAST(o_totalprice AS VARCHAR) || ' - Top Supplier: ' || COALESCE(top_supplier_name, 'None') AS description
FROM 
    FinalReport
ORDER BY 
    o_orderdate DESC, part_count DESC;
