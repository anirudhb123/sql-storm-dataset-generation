
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, CURRENT_DATE())
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
PartSummary AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity_sold,
        COALESCE(SUM(s.total_supply_cost), 0) AS total_supply_cost
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        SupplierCosts s ON p.p_partkey = s.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
),
FinalReport AS (
    SELECT 
        ps.p_partkey, 
        ps.p_name,
        ps.total_quantity_sold, 
        ps.p_retailprice,
        CASE 
            WHEN ps.total_quantity_sold > 0 THEN (ps.p_retailprice * ps.total_quantity_sold)
            ELSE 0 
        END AS revenue_generated,
        RANK() OVER (ORDER BY (CASE WHEN ps.total_quantity_sold > 0 THEN (ps.p_retailprice * ps.total_quantity_sold) ELSE 0 END) DESC) AS revenue_rank
    FROM 
        PartSummary ps
)
SELECT 
    fr.p_partkey, 
    fr.p_name, 
    fr.total_quantity_sold,
    fr.revenue_generated,
    ro.o_orderkey,
    ro.o_orderstatus,
    ro.o_totalprice
FROM 
    FinalReport fr
LEFT JOIN 
    RankedOrders ro ON fr.revenue_generated > 0 AND fr.p_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey ORDER BY l.l_extendedprice DESC LIMIT 1)
WHERE 
    fr.revenue_rank <= 10
ORDER BY 
    fr.revenue_generated DESC, fr.p_partkey;
