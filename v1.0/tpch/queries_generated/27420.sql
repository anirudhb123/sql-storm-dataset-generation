WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        CONCAT(s.s_name, ' from ', s.s_address) AS supplier_details,
        s.s_acctbal,
        n.n_name AS nation_name,
        c.c_name AS customer_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN customer c ON s.s_nationkey = c.c_nationkey
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type,
        CASE 
            WHEN p.p_size < 10 THEN 'Small'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
            ELSE 'Large' 
        END AS size_category,
        p.p_retailprice,
        p.p_comment
    FROM part p
),
Benchmarking AS (
    SELECT 
        si.supplier_details, 
        pd.p_name, 
        pd.size_category, 
        COUNT(*) AS order_count, 
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_discount) AS avg_discount,
        AVG(l.l_tax) AS avg_tax
    FROM SupplierInfo si
    JOIN partsupp ps ON si.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN PartDetails pd ON l.l_partkey = pd.p_partkey
    GROUP BY si.supplier_details, pd.p_name, pd.size_category
)
SELECT 
    supplier_details,
    p_name,
    size_category,
    order_count,
    total_quantity,
    avg_discount,
    avg_tax
FROM Benchmarking
WHERE order_count > 0
ORDER BY total_quantity DESC, avg_discount ASC;
