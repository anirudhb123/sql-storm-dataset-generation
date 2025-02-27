WITH StringAggregation AS (
    SELECT 
        p.p_partkey,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
        STRING_AGG(DISTINCT n.n_name, ', ') AS nations,
        STRING_AGG(DISTINCT c.c_name, ', ') AS customers
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN customer c ON c.c_nationkey = n.n_nationkey
    GROUP BY p.p_partkey
),
TopSuppliers AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        sa.suppliers,
        CONCAT('Total Earned: ', SUM(l.l_extendedprice * (1 - l.l_discount)), ' | Status: ', 
                CASE 
                    WHEN SUM(l.l_discount) > 0.2 THEN 'High Discount'
                    ELSE 'Standard Discount' 
                END) AS summary
    FROM part p
    JOIN StringAggregation sa ON p.p_partkey = sa.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, sa.suppliers
)
SELECT 
    CONCAT('Part: ', p.p_name, ' | Brand: ', p.p_brand, ' | Retail Price: ', p.p_retailprice, 
           ' | Suppliers: ', p.suppliers, ' | ', p.summary) AS detailed_report
FROM TopSuppliers p
ORDER BY p.p_retailprice DESC
LIMIT 10;
