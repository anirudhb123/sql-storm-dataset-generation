WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
SupplierPartStats AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
),
LineItemAggregates AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MIN(l.l_shipdate) AS first_shipdate,
        COUNT(CASE WHEN l.l_returnflag = 'Y' THEN 1 END) AS return_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(s.total_availqty, 0) AS available_quantity,
    COALESCE(sa.total_quantity, 0) AS sold_quantity,
    COALESCE(sa.total_revenue, 0) AS total_revenue,
    r.r_name AS supplier_region,
    CASE 
        WHEN r.r_name IS NULL THEN 'No supplier available'
        ELSE 'Available'
    END AS supplier_status,
    o.o_orderstatus,
    o.o_orderdate,
    o.o_totalprice
FROM 
    part p
LEFT JOIN 
    SupplierPartStats s ON p.p_partkey = s.ps_partkey
LEFT JOIN 
    LineItemAggregates sa ON p.p_partkey = sa.l_partkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RankedOrders o ON o.o_orderkey IN (
        SELECT DISTINCT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey
    )
WHERE 
    (s.total_availqty IS NOT NULL OR sa.total_quantity > 0)
ORDER BY 
    p.p_partkey
FETCH FIRST 100 ROWS ONLY;
