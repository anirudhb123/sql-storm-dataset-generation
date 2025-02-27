WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -3, GETDATE())
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_regionkey,
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    n.n_name AS nation_name,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(ss.avg_supply_cost) AS avg_cost,
    MAX(ro.o_orderdate) AS last_order_date
FROM 
    lineitem l
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
JOIN 
    RankedOrders ro ON l.l_orderkey = ro.o_orderkey
JOIN 
    SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
JOIN 
    NationRegion n ON s.s_nationkey = n.n_nationkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    l.l_shipdate >= '2023-01-01'
    AND (l.l_discount IS NULL OR l.l_discount < 0.05)
GROUP BY 
    ps.ps_partkey,
    p.p_name,
    n.n_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;
