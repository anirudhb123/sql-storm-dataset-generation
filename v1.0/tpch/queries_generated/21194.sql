WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, CURRENT_DATE) 
        AND o.o_orderstatus IN ('O', 'F')
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        SUM(ps.ps_availqty) > 1000
),
CustomerHighlights AS (
    SELECT 
        c.c_custkey,
        MAX(o.o_orderdate) AS last_order_date,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 5000
),
HighestLineitem AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS lineitem_rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)

SELECT 
    ps.part_key,
    r.r_name,
    ss.total_available,
    ch.total_spent,
    ROW_NUMBER() OVER (PARTITION BY ch.total_spent > 10000 ORDER BY ch.last_order_date DESC) AS high_spender_rank
FROM 
    part ps
LEFT JOIN 
    supplier s ON ps.p_partkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
JOIN 
    CustomerHighlights ch ON ss.part_count > 2
FULL OUTER JOIN 
    HighestLineitem hl ON ch.c_custkey = hl.l_orderkey
WHERE 
    (ss.total_available IS NOT NULL OR ch.total_spent IS NOT NULL)
    AND (ps.p_retailprice IS NOT NULL AND ps.p_size > 10)
ORDER BY 
    ch.total_spent DESC, ss.avg_supply_cost ASC;
