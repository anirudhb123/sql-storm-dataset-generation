
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
), FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_container,
        COALESCE(NULLIF(p.p_comment, ''), 'No comment') AS normalized_comment
    FROM 
        part p
    WHERE 
        EXISTS (
            SELECT 1 
            FROM partsupp ps 
            WHERE ps.ps_partkey = p.p_partkey 
            AND ps.ps_availqty > (
                SELECT AVG(ps2.ps_availqty) FROM partsupp ps2 WHERE ps2.ps_partkey = p.p_partkey
            )
        )
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus
), FinalResults AS (
    SELECT 
        fp.p_partkey,
        fp.p_name,
        COALESCE(rs.s_name, 'Unknown Supplier') AS supplier_name,
        co.total_spent,
        fp.normalized_comment
    FROM 
        FilteredParts fp
    LEFT JOIN 
        RankedSuppliers rs ON fp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rs.s_suppkey LIMIT 1)
    LEFT JOIN 
        CustomerOrders co ON fp.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey))
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    CASE WHEN f.total_spent IS NULL THEN 'No orders' ELSE CAST(f.total_spent AS VARCHAR(30)) END AS total_spent,
    f.supplier_name,
    f.normalized_comment
FROM 
    FilteredParts p
LEFT JOIN 
    FinalResults f ON p.p_partkey = f.p_partkey
ORDER BY 
    p.p_partkey ASC, 
    total_spent DESC NULLS LAST;
