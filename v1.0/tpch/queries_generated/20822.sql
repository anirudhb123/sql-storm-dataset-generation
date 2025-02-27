WITH RankedCustomer AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rnk
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(CASE 
                WHEN ps.ps_availqty > 100 THEN ps.ps_supplycost * 0.9
                ELSE ps.ps_supplycost
            END) AS adjusted_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2) 
        AND s.s_comment LIKE '%reliable%'
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
    HAVING SUM(ps.ps_availqty) > 50
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS total_parts,
        CASE 
            WHEN COUNT(DISTINCT l.l_partkey) > 5 THEN 'Diverse'
            ELSE 'Limited'
        END AS part_diversity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' 
        AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
)
SELECT 
    r.r_name,
    r.region_comment,
    COALESCE(MAX(s.acctbal), 0) AS max_supplier_acctbal,
    SUM(CASE WHEN os.part_diversity = 'Diverse' THEN os.total_revenue ELSE 0 END) AS diverse_revenue,
    COUNT(DISTINCT rc.c_custkey) FILTER (WHERE rc.rnk <= 5) AS top_customers,
    s.adjusted_cost
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN RankedCustomer rc ON n.n_nationkey = rc.c_nationkey
LEFT JOIN HighValueSuppliers s ON s.s_acctbal > 1000
LEFT JOIN OrderSummary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
GROUP BY r.r_name, r.region_comment, s.adjusted_cost
HAVING SUM(s.adjusted_cost) IS NOT NULL 
    OR COUNT(rc.c_custkey) >= 10
ORDER BY max_supplier_acctbal DESC, r.r_name;
