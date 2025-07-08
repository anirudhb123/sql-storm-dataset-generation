
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) as rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
        AND o.o_orderstatus IN ('A', 'B', 'C', 'D')
), 

SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL 
        AND s.s_comment NOT LIKE '%special%'
    GROUP BY 
        ps.ps_partkey
),

FilteredNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name
    FROM 
        nation n
    WHERE 
        n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'E%')
    UNION ALL
    SELECT 
        n.n_nationkey,
        CONCAT('Unknown_', n.n_name) 
    FROM 
        nation n
    WHERE 
        n.n_regionkey NOT IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'E%')
),

FinalSelection AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        rp.rank,
        sp.total_cost,
        fn.n_name
    FROM 
        part p
    LEFT JOIN 
        RankedOrders rp ON p.p_partkey = rp.o_orderkey
    LEFT JOIN 
        SupplierParts sp ON p.p_partkey = sp.ps_partkey
    LEFT JOIN 
        FilteredNations fn ON p.p_partkey % 10 = fn.n_nationkey % 10
    WHERE 
        (sp.total_cost IS NULL OR sp.total_cost > 1000.00)
        AND (fn.n_name IS NOT NULL OR p.p_comment IS NULL)
    GROUP BY 
        p.p_partkey, p.p_name, rp.rank, sp.total_cost, fn.n_name
)

SELECT 
    f.p_partkey,
    f.p_name,
    f.rank,
    COALESCE(f.total_cost, 0.00) AS total_cost,
    f.n_name
FROM 
    FinalSelection f
WHERE 
    f.rank <= 10
ORDER BY 
    f.total_cost DESC, f.p_name ASC
LIMIT 50
OFFSET (SELECT COUNT(*) FROM FinalSelection) / 2;
