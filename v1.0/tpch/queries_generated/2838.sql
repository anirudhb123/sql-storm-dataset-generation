WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
), CustomerSpend AS (
    SELECT 
        c.c_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spend
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
), SupplierPartSummary AS (
    SELECT 
        s.s_suppkey, 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        MAX(ps.ps_supplycost) AS max_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, p.p_name
)

SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    cs.total_spend,
    sps.p_name,
    sps.total_available_qty,
    sps.avg_supply_cost,
    sps.max_supply_cost,
    oo.total_price AS highest_order_price
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    CustomerSpend cs ON n.n_nationkey = cs.c_custkey
LEFT JOIN 
    SupplierPartSummary sps ON sps.avg_supply_cost < (SELECT AVG(avg_supply_cost) FROM SupplierPartSummary)
LEFT JOIN 
    (SELECT 
        o.o_orderkey, 
        o.o_totalprice AS total_price 
     FROM 
        RankedOrders o 
     WHERE 
        o.order_rank = 1) oo ON oo.o_orderkey = cs.c_custkey
WHERE 
    cs.total_spend IS NOT NULL AND 
    (sps.total_available_qty IS NULL OR sps.total_available_qty > 100)
ORDER BY 
    cs.total_spend DESC, 
    sps.avg_supply_cost ASC;
