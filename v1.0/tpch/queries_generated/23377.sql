WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS supplier_rank,
        SUM(ps.ps_supplycost) OVER (PARTITION BY s.s_suppkey) AS total_supplycost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown Size'
            WHEN p.p_size < 10 THEN 'Small'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
            ELSE 'Large'
        END AS size_category
    FROM part p 
    WHERE p.p_retailprice > 0
),
TopRegions AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING COUNT(n.n_nationkey) > 1
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    pr.size_category,
    os.total_price_after_discount,
    rg.r_name AS region_name
FROM FilteredParts pr
LEFT JOIN RankedSuppliers rs ON pr.p_partkey = rs.s_suppkey
FULL OUTER JOIN TopRegions rg ON rg.nation_count > 0
LEFT JOIN OrderSummary os ON pr.p_partkey = os.o_orderkey
WHERE 
    (pr.p_retailprice < 200 OR rs.total_supplycost IS NOT NULL)
    AND (rs.s_name NOT LIKE '%fake%' OR rs.s_name IS NULL)
ORDER BY 
    pr.p_retailprice DESC NULLS LAST, 
    rs.s_acctbal ASC NULLS FIRST;
