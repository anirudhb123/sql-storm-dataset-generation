WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank,
        s.s_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
), 
CustomerOrderTotals AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), 
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
), 
ComplexFilter AS (
    SELECT 
        ct.c_custkey,
        CASE 
            WHEN ct.total_spent > 5000 THEN 'High Roller'
            WHEN ct.total_spent BETWEEN 1000 AND 5000 THEN 'Average Joe'
            ELSE 'Casual Shopper'
        END AS shopper_type
    FROM 
        CustomerOrderTotals ct
), 
SupplierNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    ps.p_partkey,
    ps.total_suppliers,
    ps.total_available,
    si.s_name,
    cft.shopper_type,
    rn.rank AS supplier_rank,
    rn.s_acctbal
FROM 
    PartSupplierDetails ps
JOIN 
    RankedSuppliers rn ON rn.rank = 1 
LEFT JOIN 
    supplier si ON si.s_suppkey = rn.s_suppkey 
JOIN 
    ComplexFilter cft ON cft.c_custkey IN (
        SELECT DISTINCT c.c_custkey 
        FROM customer c 
        JOIN orders o ON c.c_custkey = o.o_custkey 
        WHERE o.o_orderstatus = 'O'
    )
WHERE 
    (ps.total_suppliers >= 5 OR ps.total_available > 100)
    AND (rn.s_acctbal IS NOT NULL OR rn.s_acctbal < 0)
ORDER BY 
    ps.total_available DESC, rn.s_acctbal DESC
LIMIT 10;
