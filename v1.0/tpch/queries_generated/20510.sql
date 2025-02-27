WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_by_balance
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000.00
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        (CASE 
             WHEN p.p_size > 50 THEN 'Large' 
             WHEN p.p_size BETWEEN 30 AND 50 THEN 'Medium' 
             ELSE 'Small' 
         END) AS size_category
    FROM 
        part p
    WHERE 
        p.p_retailprice BETWEEN 10 AND 100 AND p.p_container LIKE '%Box%'
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    s.s_name AS top_supplier,
    co.total_spent,
    ps.supplier_count,
    RANK() OVER (ORDER BY p.p_retailprice DESC) AS retail_rank,
    COALESCE(NULLIF(p.p_comment, ''), 'No comment provided') AS effective_comment
FROM 
    FilteredParts p
LEFT JOIN 
    RankedSuppliers s ON s.s_suppkey = (
        SELECT TOP 1 ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = p.p_partkey
        ORDER BY ps.ps_supplycost ASC
    )
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT TOP 1 c.c_custkey 
                                         FROM customer c 
                                         WHERE c.c_nationkey = (SELECT n.n_nationkey 
                                                                 FROM nation n 
                                                                 WHERE n.n_nationkey = s.s_nationkey)
                                         ORDER BY co.total_spent DESC)
JOIN 
    PartSupplier ps ON ps.ps_partkey = p.p_partkey
WHERE 
    s.rank_by_balance = 1 
    AND (p.p_mfgr LIKE 'Manufacturer_%' OR p.p_brand NOT LIKE 'Brand_%')
ORDER BY 
    p.p_retailprice DESC, effective_comment;
