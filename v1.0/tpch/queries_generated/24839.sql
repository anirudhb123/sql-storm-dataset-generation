WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
CustomerDetails AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal, 
        r.r_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal, r.r_name
),
PartInfo AS (
    SELECT 
        p.p_partkey, 
        SUM(ps.ps_availqty) AS total_available
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey, 
        ro.o_orderdate, 
        ro.o_totalprice,
        cd.c_name,
        cd.order_count,
        CASE 
            WHEN cd.c_acctbal > 10000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_category
    FROM 
        RankedOrders ro
    JOIN 
        CustomerDetails cd ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cd.c_custkey)
    WHERE 
        ro.rn = 1
)
SELECT 
    hvo.o_orderkey,
    hvo.o_orderdate,
    hvo.o_totalprice,
    COALESCE(pi.total_available, 0) AS total_available_parts,
    hvo.customer_category,
    COUNT(DISTINCT CASE WHEN cd.order_count > 5 THEN cd.c_name END) AS repeat_customers
FROM 
    HighValueOrders hvo
LEFT JOIN 
    PartInfo pi ON hvo.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = hvo.o_orderkey)
JOIN 
    CustomerDetails cd ON cd.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = hvo.o_orderkey)
GROUP BY 
    hvo.o_orderkey, hvo.o_orderdate, hvo.o_totalprice, pi.total_available, hvo.customer_category
HAVING 
    SUM(hvo.o_totalprice) > 10000 OR COUNT(hvo.o_orderkey) > 5
ORDER BY 
    hvo.o_orderdate DESC, total_available_parts DESC;
