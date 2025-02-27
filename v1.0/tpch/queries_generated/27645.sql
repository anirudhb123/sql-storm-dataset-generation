WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size > 10
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_phone,
        SUBSTRING(c.c_comment, 1, 25) AS short_comment
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 5000
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_clerk,
        o.o_comment,
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
)
SELECT 
    fp.p_name,
    fp.p_brand,
    fc.c_name,
    rc.r_name,
    ro.o_totalprice,
    CONCAT('Order ', ro.o_orderkey, ' from ', ro.o_orderdate::text) AS order_details
FROM 
    RankedParts fp
JOIN partsupp ps ON fp.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region rc ON n.n_regionkey = rc.r_regionkey
JOIN RecentOrders ro ON ro.o_orderkey = (
    SELECT MIN(l.l_orderkey)
    FROM lineitem l
    WHERE l.l_partkey = fp.p_partkey
)
JOIN FilteredCustomers fc ON fc.c_custkey = s.s_suppkey
WHERE 
    fp.rn <= 10
ORDER BY 
    fp.p_brand, rc.r_name, ro.o_orderdate;
