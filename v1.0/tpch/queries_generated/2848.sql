WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerSegment AS (
    SELECT 
        c.c_custkey,
        CASE 
            WHEN c.c_acctbal > 10000 THEN 'High'
            WHEN c.c_acctbal BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS segment
    FROM 
        customer c
)
SELECT 
    ns.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returns,
    AVG(s.total_supply_value) AS avg_supply_value
FROM 
    nation ns
LEFT JOIN 
    customer c ON ns.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    SupplierStats s ON s.s_suppkey = l.l_suppkey
WHERE 
    o.o_orderstatus IN ('O', 'F')
    AND l.l_shipdate < CURRENT_DATE
GROUP BY 
    ns.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC
UNION
SELECT 
    r.r_name AS region,
    NULL AS customer_count,
    NULL AS total_orders,
    NULL AS total_revenue,
    NULL AS total_returns,
    NULL AS avg_supply_value
FROM 
    region r
WHERE 
    r.r_regionkey NOT IN (SELECT DISTINCT n.n_regionkey FROM nation n);
