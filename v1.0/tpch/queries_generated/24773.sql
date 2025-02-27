WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_price
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice
    FROM 
        RankedOrders r
    WHERE 
        r.rank_price <= 10
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS supplier_nation
    FROM 
        supplier s
    INNER JOIN 
        nation n ON s.s_nationkey = n.n_nationkey 
    WHERE 
        s.s_acctbal >= (SELECT AVG(ps.ps_supplycost) FROM partsupp ps)
    ORDER BY 
        s.s_acctbal DESC
),
PartAvgPrice AS (
    SELECT 
        p.p_partkey,
        AVG(l.l_extendedprice) AS avg_price
    FROM 
        lineitem l
    INNER JOIN 
        part p ON l.l_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey
),
SuppliersWithParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        pp.p_partkey,
        p.p_name,
        p.p_container,
        pp.avg_price,
        COALESCE(SUM(ps.ps_supplycost), 0) AS total_supplycost
    FROM 
        SupplierDetails s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        PartAvgPrice pp ON ps.ps_partkey = pp.p_partkey
    INNER JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size BETWEEN 10 AND 20 OR p.p_mfgr LIKE 'Manufacturer%'
    GROUP BY 
        s.s_suppkey, s.s_name, pp.p_partkey, p.p_name, p.p_container, pp.avg_price
)
SELECT 
    so.o_orderkey,
    so.o_orderdate,
    sp.s_name,
    sp.avg_price,
    sp.total_supplycost,
    (sp.total_supplycost - so.o_totalprice) AS supply_vs_order,
    RANK() OVER (PARTITION BY so.o_orderdate ORDER BY (sp.total_supplycost - so.o_totalprice) DESC) AS rank_supply_comparison
FROM 
    TopOrders so
JOIN 
    SuppliersWithParts sp ON so.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = sp.s_suppkey)
WHERE 
    sp.total_supplycost IS NOT NULL 
    AND (sp.total_supplycost > so.o_totalprice OR so.o_orderstatus = 'F')
ORDER BY 
    so.o_orderdate, rank_supply_comparison;
