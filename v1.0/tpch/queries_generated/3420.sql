WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 1000.00
)
SELECT 
    p.p_name,
    p.p_brand,
    npal.r_name AS supplier_region,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    hc.c_name AS high_value_customer
FROM 
    part p
JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN 
    supplier s ON li.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region npal ON n.n_regionkey = npal.r_regionkey
JOIN 
    RankedOrders ro ON li.l_orderkey = ro.o_orderkey
JOIN 
    HighValueCustomers hc ON ro.o_custkey = hc.c_custkey
WHERE 
    p.p_retailprice > 50.00 AND
    li.l_quantity >= (SELECT AVG(l2.l_quantity) FROM lineitem l2 WHERE l2.l_partkey = p.p_partkey)
GROUP BY 
    p.p_name, p.p_brand, npal.r_name, hc.c_name
HAVING 
    SUM(li.l_extendedprice * (1 - li.l_discount)) > 5000.00
ORDER BY 
    total_revenue DESC;
