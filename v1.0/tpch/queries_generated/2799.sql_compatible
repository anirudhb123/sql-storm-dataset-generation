
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(s.s_suppkey) AS supplier_count
    FROM 
        nation n
    INNER JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    o.o_orderkey,
    o.o_orderstatus,
    o.o_totalprice,
    ns.region_name,
    ns.supplier_count,
    ss.total_available_qty,
    ss.avg_supply_cost,
    COALESCE(ss.unique_parts, 0) AS unique_parts_count
FROM 
    RankedOrders o
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_partkey IN (
                SELECT 
                    l.l_partkey 
                FROM 
                    lineitem l 
                WHERE 
                    l.l_orderkey = o.o_orderkey
            )
        ORDER BY 
            ps.ps_supplycost DESC 
        LIMIT 1
    )
LEFT JOIN 
    NationRegion ns ON ns.supplier_count > 5
WHERE 
    o.rn = 1
AND 
    o.o_totalprice > (
        SELECT 
            AVG(o2.o_totalprice) 
        FROM 
            orders o2 
        WHERE 
            o2.o_orderstatus = o.o_orderstatus
    )
ORDER BY 
    o.o_totalprice DESC, ns.region_name;
