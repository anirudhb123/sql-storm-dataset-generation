WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_container,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL 
        AND p.p_size BETWEEN 1 AND 50
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers,
        AVG(s.s_acctbal) AS avg_acctbal,
        MAX(s.s_acctbal) AS max_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    r.r_name,
    ps.total_suppliers,
    ps.avg_acctbal,
    COALESCE(MAX(co.total_spent), 0) AS max_spent,
    GROUP_CONCAT(DISTINCT rp.p_name) AS popular_parts
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierStats ps ON ps.s_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey ORDER BY c.c_acctbal DESC LIMIT 1)
LEFT JOIN 
    RankedParts rp ON rp.brand_rank <= 5
GROUP BY 
    r.r_name
HAVING 
    ps.total_suppliers > 10 OR (ps.avg_acctbal IS NULL AND COUNT(rp.p_partkey) > 0)
ORDER BY 
    r.r_name DESC;
