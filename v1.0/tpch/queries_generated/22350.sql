WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey
    )
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 'Unknown Price'
            WHEN p.p_retailprice > 100 THEN 'Expensive'
            WHEN p.p_retailprice BETWEEN 50 AND 100 THEN 'Moderate'
            ELSE 'Cheap' 
        END AS price_category
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT ps.ps_supplycost FROM partsupp ps WHERE ps.ps_availqty < 10)
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS line_item_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
FinalOutput AS (
    SELECT 
        fp.p_name,
        rp.s_name AS supplier_name,
        os.total_sales,
        os.line_item_count,
        os.last_order_date
    FROM FilteredParts fp
    LEFT JOIN RankedSuppliers rp ON rp.rn = 1 AND rp.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey = fp.p_partkey
    )
    JOIN OrderStats os ON os.o_orderkey = (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderstatus = 'O' AND o.o_orderkey = (
            SELECT l.l_orderkey 
            FROM lineitem l 
            WHERE l.l_partkey = fp.p_partkey 
            ORDER BY l.l_extendedprice DESC 
            LIMIT 1
        )
    )
)
SELECT DISTINCT 
    fp.price_category,
    COUNT(DISTINCT fo.supplier_name) AS suppliers_count,
    SUM(fo.total_sales) AS total_sales_sum
FROM FinalOutput fo
JOIN FilteredParts fp ON fp.p_partkey = fo.p_partkey
WHERE fp.p_name LIKE '%bolt%'
GROUP BY fp.price_category
HAVING SUM(fo.total_sales) > 1000
ORDER BY total_sales_sum DESC
LIMIT 5;
