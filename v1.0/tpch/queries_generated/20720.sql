WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_container IN ('SM BOX', 'MED BOX', 'LG BOX')
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_comment IS NOT NULL)
), 
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS line_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
), 
FilteredOrders AS (
    SELECT 
        os.o_orderkey,
        os.o_custkey,
        os.total_sales,
        os.line_items,
        ROW_NUMBER() OVER (PARTITION BY os.o_custkey ORDER BY os.total_sales DESC) AS sales_rank
    FROM 
        OrderStats os
    WHERE 
        EXISTS (
            SELECT 1 
            FROM SupplierInfo si 
            WHERE si.s_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = os.o_custkey)
            AND si.s_acctbal > 0
        )
)
SELECT 
    f.customer_name,
    p.p_name,
    f.total_sales,
    f.line_items,
    COALESCE(p.price_rank, 'N/A') AS price_rank,
    f.sales_rank
FROM 
    customer c
LEFT JOIN 
    FilteredOrders f ON c.c_custkey = f.o_custkey
LEFT JOIN 
    RankedParts p ON f.o_orderkey = p.p_partkey
WHERE 
    (f.total_sales IS NOT NULL OR p.p_retailprice > 50.00)
    AND NOT (f.line_items = 0 AND f.total_sales < 0)
ORDER BY 
    f.total_sales DESC NULLS LAST, 
    c.c_name ASC;
