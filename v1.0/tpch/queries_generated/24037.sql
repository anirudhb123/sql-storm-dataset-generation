WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_retailprice, 
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p1.p_retailprice) FROM part p1 WHERE p1.p_size < 20)
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_nationkey,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 0
            ELSE s.s_acctbal
        END AS adjusted_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
LineitemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        AVG(l.l_quantity) AS avg_quantity,
        COUNT(DISTINCT l.l_suppkey) AS distinct_suppliers
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
NationMetrics AS (
    SELECT 
        n.n_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n 
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey
),
FinalMetrics AS (
    SELECT 
        r.r_name,
        COALESCE(nm.supplier_count, 0) AS total_suppliers,
        COALESCE(nm.total_acctbal, 0) AS total_acctbal,
        COUNT(DISTINCT cp.c_custkey) AS total_customers,
        COUNT(DISTINCT lp.l_orderkey) AS total_orders
    FROM 
        region r
    LEFT JOIN 
        NationMetrics nm ON r.r_regionkey = nm.n_nationkey 
    LEFT JOIN 
        CustomerOrderCounts cp ON cp.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = nm.n_nationkey)
    LEFT JOIN 
        LineitemStats lp ON lp.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = nm.n_nationkey))
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r.r_name,
    COALESCE(rp.p_name, 'No Parts') AS part_example,
    fm.total_suppliers,
    fm.total_acctbal,
    fm.total_customers,
    fm.total_orders
FROM 
    FinalMetrics fm
LEFT JOIN 
    RankedParts rp ON rp.rn = 1
JOIN 
    region r ON fm.r_name = r.r_name
WHERE 
    fm.total_acctbal > 1000 AND 
    fm.total_orders IS NOT NULL
ORDER BY 
    fm.total_customers DESC, 
    fm.total_suppliers ASC;
