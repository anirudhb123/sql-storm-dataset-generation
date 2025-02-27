WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('F', 'O')
), 
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), 
HighValueCustomers AS (
    SELECT DISTINCT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) OVER (PARTITION BY c.c_custkey) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
), 
TotalLineItems AS (
    SELECT 
        l.l_orderkey,
        COUNT(l.l_linenumber) AS item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    r.r_name,
    COUNT(DISTINCT so.o_orderkey) AS order_count,
    COALESCE(MAX(sp.total_avail_qty), 0) AS max_avail_qty,
    AVG(sp.avg_supply_cost) AS avg_supply_cost,
    SUM(tli.total_lineitem_value) AS total_order_value,
    CASE 
        WHEN COUNT(DISTINCT c.c_custkey) > 10 THEN 'High Engagement' 
        ELSE 'Low Engagement' 
    END AS engagement_level
FROM 
    part p
LEFT OUTER JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    RankedOrders so ON l.l_orderkey = so.o_orderkey
JOIN 
    HighValueCustomers c ON so.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = c.c_custkey)
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    TotalLineItems tli ON l.l_orderkey = tli.l_orderkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    AND r.r_name IS NOT NULL
GROUP BY 
    p.p_partkey, p.p_name, r.r_name
HAVING 
    COUNT(DISTINCT so.o_orderkey) > 2
ORDER BY 
    total_order_value DESC, max_avail_qty ASC
LIMIT 50 OFFSET 10;
