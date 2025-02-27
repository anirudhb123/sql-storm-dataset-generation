WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    WHERE
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        (p.p_retailprice * SUM(l.l_quantity) / NULLIF(SUM(l.l_quantity), 0)) AS avg_cost
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        p.p_retailprice > 100.00
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
),
FinalResults AS (
    SELECT 
        ro.o_orderkey,
        fp.p_name,
        fp.avg_cost,
        sd.total_supply_cost,
        ro.o_totalprice,
        CASE 
            WHEN ro.o_totalprice > 1000 THEN 'High'
            ELSE 'Low'
        END AS price_category
    FROM 
        RankedOrders ro
    JOIN 
        FilteredParts fp ON ro.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = fp.p_partkey)
    LEFT JOIN 
        SupplierDetails sd ON sd.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = fp.p_partkey LIMIT 1)
)
SELECT 
    r.o_orderkey,
    r.p_name,
    r.avg_cost,
    COALESCE(r.total_supply_cost, 0) AS total_supply_cost,
    r.o_totalprice,
    r.price_category
FROM 
    FinalResults r
WHERE 
    r.avg_cost IS NOT NULL
ORDER BY 
    r.o_orderkey, r.avg_cost DESC;
