WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_within_nation
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_comment,
        COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice, p.p_comment
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 5
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_partkey) AS items_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    rs.s_name,
    p.p_name,
    hp.num_suppliers,
    os.total_sales,
    os.items_count,
    CASE 
        WHEN os.last_order_date IS NULL THEN 'No orders'
        ELSE TO_CHAR(os.last_order_date, 'YYYY-MM-DD')
    END AS last_order_date_formatted,
    COALESCE(NULLIF(RTRIM(s.s_comment), ''), 'No Comment') AS supplier_comment
FROM 
    RankedSuppliers rs
LEFT JOIN 
    HighValueParts hp ON rs.rank_within_nation <= 3
LEFT JOIN 
    OrderStats os ON os.items_count > 0
WHERE 
    hp.p_retailprice > ALL (SELECT AVG(p2.p_retailprice) FROM part p2)
    AND rs.s_acctbal < (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = rs.s_nationkey)
ORDER BY 
    hp.num_suppliers DESC, total_sales DESC, rs.s_name ASC
FETCH FIRST 100 ROWS ONLY;
