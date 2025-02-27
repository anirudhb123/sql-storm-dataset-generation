WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_type,
        p.p_size,
        COUNT(ps.ps_partkey) AS supply_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_mfgr ORDER BY COUNT(ps.ps_partkey) DESC) AS mfgr_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_type, p.p_size
),
BestParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        rp.p_type,
        rp.p_size,
        rp.supply_count,
        rp.total_supply_cost
    FROM 
        RankedParts rp
    WHERE 
        rp.mfgr_rank = 1
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, l.l_partkey
)
SELECT 
    bp.p_name,
    bp.p_mfgr,
    bp.p_type,
    od.o_orderdate,
    SUM(od.total_quantity) AS aggregated_quantity,
    SUM(od.total_revenue) AS aggregated_revenue,
    ROUND(AVG(bp.total_supply_cost), 2) AS avg_supply_cost
FROM 
    BestParts bp
JOIN 
    OrderDetails od ON bp.p_partkey = od.l_partkey
GROUP BY 
    bp.p_name, bp.p_mfgr, bp.p_type, od.o_orderdate
ORDER BY 
    bp.p_mfgr, aggregated_revenue DESC;
