WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
        AND o.o_orderdate < DATE '2023-12-31'
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2
            WHERE s2.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = 1)
        )
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0) AS total_revenue,
    r.r_name,
    n.n_name,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY total_revenue DESC) AS region_revenue_rank,
    DISTINCT(CASE WHEN co.order_count >= 5 THEN 'Frequent Buyer' ELSE 'Occasional Buyer' END) AS customer_type
FROM 
    part p
JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
JOIN 
    supplier s ON li.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    customer c ON li.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerOrderCount co ON c.c_custkey = co.c_custkey
WHERE 
    EXISTS (
        SELECT 1 
        FROM HighValueSuppliers hvs 
        WHERE hvs.s_suppkey = s.s_suppkey
    )
    AND li.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
GROUP BY 
    p.p_name, r.r_name, n.n_name, co.order_count
HAVING 
    SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
ORDER BY 
    region_revenue_rank;
