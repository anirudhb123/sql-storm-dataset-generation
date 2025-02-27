WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
MaxCustomerOrder AS (
    SELECT 
        o.o_custkey,
        MAX(o.o_totalprice) AS max_total_price
    FROM orders o
    GROUP BY o.o_custkey
),
CustomerRegions AS (
    SELECT 
        c.c_custkey,
        r.r_name AS region_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
SupplierInfo AS (
    SELECT 
        r.r_name AS region_name,
        s.s_name,
        s.s_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
)
SELECT 
    cr.region_name,
    si.s_name,
    SUM(si.s_acctbal) AS total_acct_bal,
    COUNT(DISTINCT cs.o_custkey) AS customer_count,
    MAX(COALESCE(rsu.s_name, 'No Supplier')) AS top_supplier_name
FROM CustomerRegions cr
LEFT JOIN SupplierInfo si ON cr.region_name = si.region_name
LEFT JOIN RankedSuppliers rsu ON si.s_suppkey = rsu.s_suppkey AND rsu.supplier_rank = 1
LEFT JOIN MaxCustomerOrder cs ON cr.c_custkey = cs.o_custkey
GROUP BY cr.region_name
HAVING SUM(si.s_acctbal) > 5000
ORDER BY total_acct_bal DESC, cr.region_name;
