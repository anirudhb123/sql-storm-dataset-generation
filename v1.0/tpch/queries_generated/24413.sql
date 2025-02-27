WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) as rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL AND 
        ps.ps_availqty > 0
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) as rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= DATEADD(month, -3, GETDATE())
),
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(RS.s_name, 'No Supplier') AS SupplierName,
    COALESCE(RS.s_acctbal, 0) AS SupplierAccountBalance,
    R.ordermtclext AS OrderTotal,
    (CASE 
        WHEN R.ordermtclext IS NULL THEN 'No Order' 
        ELSE 'Has Order' 
     END) AS OrderStatus,
    SPI.num_suppliers,
    SPI.avg_supplycost,
    (SELECT 
        COUNT(*) 
     FROM 
        lineitem l 
     WHERE 
        l.l_partkey = p.p_partkey 
        AND l.l_returnflag = 'R') AS returned_quantity
FROM 
    part p
LEFT JOIN 
    RankedSuppliers RS ON p.p_partkey = RS.s_suppkey AND RS.rnk = 1
LEFT JOIN 
    RecentOrders R ON R.o_custkey = (
        SELECT c.c_custkey FROM customer c 
        WHERE c.c_nationkey = (
            SELECT n.n_nationkey FROM nation n 
            WHERE n.n_name = 'FRANCE'
        )
    )
LEFT JOIN 
    SupplierPartInfo SPI ON p.p_partkey = SPI.ps_partkey
WHERE 
    (p.p_retailprice > 50 OR p.p_size BETWEEN 10 AND 100)
    AND (p.p_comment NOT LIKE '%obsolete%' OR p.p_size IS NULL)
ORDER BY 
    p.p_partkey DESC, 
    SupplierAccountBalance ASC
OPTION (RECOMPILE);
