WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
), 
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_extendedprice,
        DENSE_RANK() OVER (PARTITION BY l.l_partkey ORDER BY l.l_discount DESC) AS discount_rank
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N' 
        AND l.l_discount BETWEEN 0.1 AND 0.5
)

SELECT 
    p.p_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    MAX(s.s_acctbal) AS max_supplier_balance,
    CASE 
        WHEN AVG(s.s_acctbal) IS NULL THEN 'No Suppliers'
        ELSE CAST(AVG(s.s_acctbal) AS CHAR)
    END AS avg_supplier_balance
FROM 
    part p
LEFT JOIN 
    FilteredLineItems l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    HighValueCustomers c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    RankedSuppliers s ON l.l_partkey = s.ps_partkey AND s.rank = 1
WHERE 
    p.p_retailprice IS NOT NULL OR p.p_comment IS NOT NULL
GROUP BY 
    p.p_name
HAVING 
    total_sales > (
        SELECT 
            AVG(total_sales) 
        FROM (
            SELECT 
                SUM(l2.l_extendedprice * (1 - l2.l_discount)) AS total_sales
            FROM 
                FilteredLineItems l2
            GROUP BY 
                l2.l_partkey
        ) AS sales_avg
    )
ORDER BY 
    total_sales DESC, p.p_name;
