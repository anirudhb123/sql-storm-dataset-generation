WITH RECURSIVE SupplierPart AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrder AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        COUNT(l.l_orderkey) AS total_line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, o.o_orderkey
),
RegionRanking AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT n.n_nationkey) DESC) AS rnk
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    sp.s_name,
    sp.s_acctbal,
    co.c_name,
    co.o_orderkey,
    co.o_totalprice,
    co.net_revenue,
    rg.r_name,
    rg.nation_count
FROM 
    SupplierPart sp
JOIN 
    CustomerOrder co ON co.total_line_items > 5  -- Filtering based on total line items
LEFT JOIN 
    RegionRanking rg ON rg.rnk <= 3  -- Including only top 3 regions by nation count
WHERE 
    sp.rn = 1 AND sp.s_acctbal IS NOT NULL
ORDER BY 
    co.net_revenue DESC, sp.s_name ASC
LIMIT 100;
