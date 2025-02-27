WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
        AND o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
), 
CustomerTotalSpend AS (
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
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    c.c_name,
    r.r_name AS region,
    SUM(cts.total_spend) AS total_customer_spend,
    COALESCE(SUM(sa.total_available), 0) AS total_available_parts,
    MAX(ro.o_orderdate) AS last_order_date
FROM 
    CustomerTotalSpend cts
JOIN 
    customer c ON c.c_custkey = cts.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RankedOrders ro ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = ro.o_orderkey)
LEFT JOIN 
    SupplierAvailability sa ON sa.ps_partkey IN (SELECT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_custkey = c.c_custkey)
WHERE 
    c.c_acctbal IS NOT NULL
GROUP BY 
    c.c_name, r.r_name
HAVING 
    SUM(cts.total_spend) > 10000
ORDER BY 
    total_customer_spend DESC, r.r_name ASC;
