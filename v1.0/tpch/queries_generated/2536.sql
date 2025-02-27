WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerWithHighBalance AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (
            SELECT AVG(c2.c_acctbal)
            FROM customer c2
        )
)
SELECT 
    r.r_name,
    COUNT(DISTINCT co.c_custkey) AS num_customers,
    AVG(co.c_acctbal) AS avg_balance,
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_revenue,
    MAX(wo.o_orderdate) AS last_order_date
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    SupplierParts sp ON ps.ps_partkey = sp.ps_partkey
LEFT JOIN 
    lineitem lp ON ps.ps_partkey = lp.l_partkey
LEFT JOIN 
    (SELECT DISTINCT o.o_orderkey, c.c_custkey 
     FROM RankedOrders o 
     INNER JOIN customer c ON o.o_orderkey = c.c_custkey) co ON lp.l_orderkey = co.o_orderkey
WHERE 
    sp.total_available > 0 
    AND n.n_nationkey IN (SELECT n_nationkey FROM CustomerWithHighBalance) 
GROUP BY 
    r.r_name
HAVING 
    AVG(co.c_acctbal) IS NOT NULL
ORDER BY 
    total_revenue DESC;
