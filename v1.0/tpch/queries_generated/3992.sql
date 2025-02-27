WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank_price
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
HighValueSuppliers AS (
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
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        AVG(l.l_extendedprice) AS avg_price
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.c_name,
    COALESCE(pd.p_name, 'Unknown Part') AS part_name,
    COALESCE(ps.s_name, 'No Supplier') AS supplier_name,
    ps.total_supply_cost,
    pd.avg_price
FROM 
    RankedOrders r
LEFT JOIN 
    PartDetails pd ON r.o_orderkey = pd.p_partkey -- Correlated join, assuming order key maps to part in some context
LEFT JOIN 
    HighValueSuppliers ps ON ps.s_suppkey = (
        SELECT ps2.ps_suppkey 
        FROM partsupp ps2 
        WHERE ps2.ps_partkey = pd.p_partkey 
        ORDER BY ps2.ps_supplycost DESC 
        LIMIT 1
    )
WHERE 
    r.rank_price <= 5 -- Top 5 by market segment
ORDER BY 
    r.o_orderdate DESC, 
    r.o_totalprice DESC;
