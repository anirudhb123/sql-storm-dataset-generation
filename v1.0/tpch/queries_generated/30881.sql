WITH RECURSIVE SalesCTE AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) as rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    UNION ALL
    SELECT 
        CTE.o_orderkey,
        CTE.o_orderdate,
        CTE.o_totalprice * 1.1, 
        CTE.c_mktsegment,
        CTE.rn
    FROM 
        SalesCTE CTE
    WHERE 
        CTE.rn < 5
),
SupplierPart AS (
    SELECT 
        ps.ps_partkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps 
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
),
FinalSummary AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand,
        sp.total_available,
        sp.avg_supply_cost,
        COALESCE(sct.o_totalprice, 0) as total_sales,
        COALESCE(SUM(sct.o_totalprice) FILTER (WHERE sct.c_mktsegment = 'AUTOMOBILE'), 0) as auto_sales
    FROM 
        part p 
    LEFT JOIN 
        SupplierPart sp ON p.p_partkey = sp.ps_partkey
    LEFT JOIN 
        SalesCTE sct ON p.p_partkey = sct.o_orderkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, sp.total_available, sp.avg_supply_cost
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand,
    p.total_available, 
    p.avg_supply_cost, 
    p.total_sales, 
    p.auto_sales,
    CASE 
        WHEN p.total_sales IS NULL THEN 'No Sales'
        WHEN p.auto_sales > 10000 THEN 'High Demand'
        ELSE 'Regular Demand' 
    END AS demand_category,
    (p.total_sales - p.auto_sales) / NULLIF(p.total_sales, 0) AS sales_difference_ratio
FROM 
    FinalSummary p
ORDER BY 
    p.total_sales DESC NULLS LAST
LIMIT 100;
