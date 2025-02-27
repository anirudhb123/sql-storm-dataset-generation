WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
        AND o.o_orderdate < DATE '2023-12-31'
),
SuspiciousSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        total_supply_cost > (SELECT AVG(ps_supplycost) FROM partsupp) 
        AND part_count < 5
),
UnfulfilledOrders AS (
    SELECT 
        o.o_orderkey,
        MAX(i.l_shipdate) AS latest_shipdate
    FROM 
        orders o 
    LEFT JOIN 
        lineitem i ON o.o_orderkey = i.l_orderkey 
    WHERE 
        i.l_returnflag IS NULL OR i.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
    HAVING 
        MAX(i.l_commitdate) < MIN(i.l_shipdate)
)
SELECT 
    DISTINCT 
    r.r_name,
    COUNT(DISTINCT nos.o_orderkey) AS unfulfilled_count,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_extended_price,
    CASE
        WHEN COUNT(DISTINCT nos.o_orderkey) > 0 THEN 'Potentially Issue'
        ELSE 'All Orders Fulfilled'
    END AS order_status
FROM 
    region r 
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    UnfulfilledOrders nos ON nos.o_orderkey = (SELECT MIN(o.o_orderkey) FROM RankedOrders oo WHERE oo.o_orderdate = nos.o_orderdate)
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
WHERE 
    s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
    AND r.r_name LIKE 'S%'
GROUP BY 
    r.r_name
ORDER BY 
    unfulfilled_count DESC, total_supply_cost DESC;
