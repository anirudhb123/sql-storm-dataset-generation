WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank_acct
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        (CASE 
            WHEN p.p_size > 20 THEN 'Large'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
            ELSE 'Small' 
        END) AS size_category,
        p.p_retailprice * (1 - SUM(l.l_discount) OVER (PARTITION BY l.l_partkey)) AS effective_price
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        p.p_retailprice IS NOT NULL
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.size_category,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    fp.effective_price,
    (SELECT COUNT(*) 
     FROM orders o
     WHERE o.o_orderkey IN (SELECT l.l_orderkey 
                             FROM lineitem l 
                             WHERE l.l_partkey = fp.p_partkey)) AS order_count
FROM 
    FilteredParts fp
LEFT JOIN 
    RankedSupplier rs ON fp.size_category = (CASE 
                                               WHEN rs.rank_acct < 5 THEN 'Large' 
                                               ELSE 'Small' 
                                              END)
WHERE 
    fp.effective_price IS NOT NULL
    AND fp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps 
                          WHERE ps.ps_supplycost > 100.00)
ORDER BY 
    fp.size_category, fp.effective_price DESC
FETCH FIRST 100 ROWS ONLY;
