WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        YEAR(o.o_orderdate) = 1997 
        AND l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
TopRevenueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        r.total_revenue
    FROM 
        RankedOrders r 
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    WHERE 
        r.revenue_rank <= 10
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
ExpensiveParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 'Unknown' 
            ELSE 'Known' 
        END AS price_status
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
FinalReport AS (
    SELECT 
        o.o_orderkey,
        e.p_partkey,
        e.p_name,
        COALESCE(sd.unique_suppliers, 0) AS supplier_count,
        CASE 
            WHEN e.price_status = 'Known' THEN 'Expensive Part'
            ELSE 'No Price'
        END AS part_status
    FROM 
        TopRevenueOrders o
    LEFT JOIN 
        ExpensiveParts e ON EXISTS (SELECT 1 FROM lineitem l WHERE l.l_orderkey = o.o_orderkey AND l.l_partkey = e.p_partkey)
    LEFT JOIN 
        SupplierDetails sd ON e.p_partkey = sd.ps_partkey
)
SELECT 
    fr.o_orderkey,
    fr.p_partkey,
    fr.p_name,
    fr.supplier_count,
    fr.part_status
FROM 
    FinalReport fr
WHERE 
    fr.supplier_count > (SELECT AVG(supplier_count) FROM (SELECT COUNT(DISTINCT ps_suppkey) AS supplier_count FROM partsupp GROUP BY ps_partkey) AS supplier_stats)
ORDER BY 
    fr.o_orderkey, fr.p_partkey;
