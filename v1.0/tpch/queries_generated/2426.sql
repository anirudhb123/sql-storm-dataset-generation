WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 10000
    GROUP BY 
        s.s_suppkey, s.s_name
),
LineItemAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '2023-06-01' AND DATE '2023-09-30'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    ra.total_revenue,
    ra.avg_quantity,
    COALESCE(sd.total_supply_cost, 0) AS total_supply_cost,
    COUNT(DISTINCT n.n_nationkey) AS unique_nations
FROM 
    RankedOrders o
LEFT JOIN 
    LineItemAggregates ra ON o.o_orderkey = ra.l_orderkey
LEFT JOIN 
    supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_mfgr = 'ManufacturerX'))
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
WHERE 
    o.order_rank <= 10
AND 
    (o.o_orderstatus = 'F' OR o.o_orderstatus = 'R') 
GROUP BY 
    o.o_orderkey, o.o_orderdate, ra.total_revenue, ra.avg_quantity, sd.total_supply_cost
ORDER BY 
    o.o_orderdate DESC;
