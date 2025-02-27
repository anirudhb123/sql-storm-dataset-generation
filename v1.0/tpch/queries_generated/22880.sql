WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' 
        AND o.o_orderdate < DATE '2023-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name
),
PartAggregation AS (
    SELECT 
        p.p_partkey, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
FinalResult AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderstatus,
        ro.o_totalprice,
        pd.supplier_count,
        sd.total_supply_cost,
        CASE 
            WHEN ro.o_orderstatus = 'F' THEN 'Finished'
            WHEN ro.o_orderstatus = 'P' AND sd.total_supply_cost > 1000 THEN 'Pending with high cost'
            ELSE 'Other' 
        END AS status_description
    FROM 
        RankedOrders ro
    LEFT JOIN 
        PartAggregation pd ON pd.supplier_count > 0
    LEFT JOIN 
        SupplierDetails sd ON sd.part_count > 0
    WHERE 
        (ro.o_orderstatus IS NOT NULL AND sd.total_supply_cost IS NOT NULL)
        OR (ro.o_orderstatus IS NULL AND sd.total_supply_cost IS NULL)
)
SELECT 
    f.o_orderkey, 
    f.o_orderstatus, 
    f.o_totalprice, 
    COALESCE(f.supplier_count, 0) AS supplier_count, 
    COALESCE(f.total_supply_cost, 0.00) AS total_supply_cost,
    f.status_description
FROM 
    FinalResult f
WHERE 
    f.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_totalprice > 500)
ORDER BY 
    f.o_totalprice DESC
FETCH FIRST 10 ROWS ONLY;
