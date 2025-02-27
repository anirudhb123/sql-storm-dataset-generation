WITH RECURSIVE SupplierPartCount AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
RegionAveragePrice AS (
    SELECT 
        n.n_regionkey,
        AVG(l.l_extendedprice) AS avg_price
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_regionkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    c.c_custkey,
    c.c_name,
    COALESCE(so.part_count, 0) AS distinct_parts_supplied,
    COALESCE(rap.avg_price, 0.00) AS avg_price_in_region,
    cos.total_spent,
    cos.order_count
FROM 
    customer c
LEFT JOIN 
    SupplierPartCount so ON so.s_suppkey = (
        SELECT s.s_suppkey 
        FROM supplier s 
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
        WHERE ps.ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp) 
        LIMIT 1
    )
LEFT JOIN 
    RegionAveragePrice rap ON rap.n_regionkey = (
        SELECT n.n_regionkey 
        FROM nation n 
        WHERE n.n_nationkey = c.c_nationkey
    )
JOIN 
    CustomerOrderSummary cos ON cos.c_custkey = c.c_custkey
WHERE 
    cos.total_spent > (
        SELECT AVG(total_spent) 
        FROM CustomerOrderSummary
    ) 
    AND c.c_acctbal IS NOT NULL
ORDER BY 
    c.c_custkey;
