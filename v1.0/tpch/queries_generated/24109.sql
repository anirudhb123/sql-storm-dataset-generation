WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        SUM(ps.ps_availqty) AS total_availqty,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY COUNT(DISTINCT ps.ps_suppkey) DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size BETWEEN 10 AND 30
    GROUP BY 
        p.p_partkey, p.p_name, p.p_type
), FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(o.o_totalprice) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL AND COUNT(o.o_orderkey) > 5
), SupplierNation AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COALESCE(NULLIF(s.s_comment, ''), 'No Comment') AS supplier_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal < (SELECT AVG(s2.s_acctbal) FROM supplier s2)
)
SELECT 
    r.p_partkey,
    r.p_name,
    f.c_custkey,
    f.c_name,
    f.total_spent,
    COALESCE(s.supplier_comment, 'No Supplier Comment') AS supplier_comment,
    f.order_count,
    CASE 
        WHEN f.order_count > 10 THEN 'High Value'
        WHEN f.order_count BETWEEN 5 AND 10 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_status
FROM 
    RankedParts r
FULL OUTER JOIN 
    FilteredCustomers f ON f.rn = 1 AND f.order_count IS NOT NULL
LEFT JOIN 
    SupplierNation s ON r.supplier_count = (SELECT MAX(supplier_count) FROM RankedParts)
WHERE 
    r.rn <= 5 OR s.supplier_comment IS NOT NULL
ORDER BY 
    r.avg_supplycost DESC, f.total_spent ASC;
