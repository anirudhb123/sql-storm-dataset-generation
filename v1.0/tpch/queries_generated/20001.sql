WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2023-12-31'
),
SupplierAggregates AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
)
SELECT 
    r.r_name,
    n.n_name,
    s.s_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT o.o_orderpriority) FILTER (WHERE o.o_orderstatus = 'F') AS fulfilled_orders_priority,
    CASE 
        WHEN MAX(s.s_acctbal) IS NULL THEN 0
        ELSE AVG(s.s_acctbal)
    END AS average_acct_balance,
    COALESCE(AVG(sa.total_supplycost), 0) AS avg_supplycost_per_supplier,
    COUNT(CASE WHEN li.l_returnflag = 'R' THEN 1 END) AS total_returns,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(li.l_extendedprice) DESC) AS region_rank
FROM 
    lineitem li
JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON li.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierAggregates sa ON s.s_suppkey = sa.ps_suppkey
WHERE 
    li.l_shipdate >= o.o_orderdate
AND 
    li.l_shipmode IN ('AIR', 'GROUND')
GROUP BY 
    r.r_name, n.n_name, s.s_name
HAVING 
    SUM(li.l_extendedprice) > 100000
ORDER BY 
    region_rank, total_revenue DESC;
