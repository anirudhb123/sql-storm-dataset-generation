WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_retailprice,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity_sold,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_retailprice
),
FinalReport AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        ps.p_name AS part_name,
        ps.total_quantity_sold,
        ps.total_revenue,
        so.rn AS latest_order_rn
    FROM 
        SupplierDetails s
    JOIN 
        part ps ON ps.p_partkey = (
            SELECT ps_partkey FROM partsupp pp WHERE pp.ps_suppkey = s.s_suppkey LIMIT 1
        )
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        RankedOrders so ON so.o_orderkey = (
            SELECT l.l_orderkey 
            FROM lineitem l 
            WHERE l.l_partkey = ps.p_partkey ORDER BY l.l_shipdate DESC LIMIT 1
        )
)
SELECT 
    region_name,
    nation_name,
    supplier_name,
    part_name,
    total_quantity_sold,
    total_revenue
FROM 
    FinalReport
WHERE 
    total_revenue > 10000 
ORDER BY 
    total_revenue DESC
LIMIT 10;
