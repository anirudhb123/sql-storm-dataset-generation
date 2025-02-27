WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_mktsegment = c.c_mktsegment)
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS recent_order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        (SELECT COUNT(ps.ps_partkey) 
         FROM partsupp ps 
         WHERE ps.ps_suppkey = s.s_suppkey AND ps.ps_availqty > 0) AS available_parts,
        MAX(ps.ps_supplycost) OVER (PARTITION BY s.s_suppkey) AS max_supplycost
    FROM 
        supplier s
),
PartPricing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS order_count
    FROM 
        part p 
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey 
    WHERE 
        l.l_shipdate >= DATE '2023-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    nc.c_custkey,
    nc.c_name,
    ps.s_suppkey,
    ps.s_name,
    pp.p_partkey,
    pp.p_name,
    pp.total_revenue,
    pp.order_count,
    rc.rank,
    sd.available_parts,
    sd.max_supplycost
FROM 
    RankedCustomers rc
JOIN 
    RecentOrders ro ON rc.c_custkey = ro.o_custkey
FULL OUTER JOIN 
    SupplierDetails sd ON sd.available_parts > 0
LEFT JOIN 
    PartPricing pp ON pp.order_count > 1
LEFT JOIN 
    partsupp ps ON pp.p_partkey = ps.ps_partkey AND ps.ps_availqty IS NOT NULL
WHERE 
    (rc.rank <= 5 OR ps.s_name IS NULL)
    AND (pp.total_revenue IS NOT NULL OR pp.order_count = 0)
ORDER BY 
    nc.c_custkey, pp.total_revenue DESC NULLS LAST;
