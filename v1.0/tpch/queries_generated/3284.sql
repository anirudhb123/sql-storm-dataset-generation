WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate <= DATE '2023-12-31'
    GROUP BY 
        l.l_partkey
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(ts.total_sales, 0) AS total_sales
    FROM 
        part p
    LEFT JOIN 
        TotalSales ts ON p.p_partkey = ts.l_partkey
    WHERE 
        p.p_retailprice > 100.00
),
CustomerSegment AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        CASE 
            WHEN SUM(o.o_totalprice) > 1000 THEN 'High'
            WHEN SUM(o.o_totalprice) BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS segment
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    tp.p_partkey,
    tp.p_name,
    tp.total_sales,
    cs.c_name,
    cs.total_spent,
    cs.segment,
    CASE 
        WHEN rs.rank = 1 THEN 'Top Supplier'
        ELSE 'Other Supplier'
    END AS supplier_rank
FROM 
    TopParts tp
LEFT JOIN 
    RankedSuppliers rs ON tp.p_partkey = rs.ps_partkey AND rs.rank = 1
JOIN 
    CustomerSegment cs ON cs.total_spent IS NOT NULL
WHERE 
    (tp.total_sales > 500 OR cs.segment = 'High')
ORDER BY 
    tp.total_sales DESC, cs.total_spent DESC;
