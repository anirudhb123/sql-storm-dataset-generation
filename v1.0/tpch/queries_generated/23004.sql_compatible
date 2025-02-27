
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate > '1996-01-01' 
        AND o.o_orderdate < '1997-01-01'
),
SupplierStats AS (
    SELECT
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
LineItemAnalyses AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) FILTER (WHERE l.l_returnflag = 'R') AS return_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    COALESCE(ss.num_parts, 0) AS supplier_part_count,
    COALESCE(ss.avg_supplycost, 0.00) AS supplier_avg_cost,
    la.total_revenue,
    la.return_count,
    CASE 
        WHEN la.return_count > 0 THEN 'Returned'
        WHEN la.total_revenue IS NULL THEN 'No Data'
        ELSE 'Complete'
    END AS order_status
FROM 
    RankedOrders o
LEFT JOIN 
    LineItemAnalyses la ON o.o_orderkey = la.l_orderkey
LEFT JOIN 
    SupplierStats ss ON o.o_orderkey = (SELECT MIN(lp.l_orderkey) FROM lineitem lp WHERE lp.l_orderkey = o.o_orderkey)
WHERE 
    o.order_rank <= 5
ORDER BY 
    o.o_orderdate DESC,
    total_revenue DESC NULLS LAST;
