WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
EligibleParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS aggregate_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
    HAVING SUM(ps.ps_availqty) > 1000
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(DISTINCT l.l_linenumber) AS total_lines,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    es.p_partkey,
    es.p_name,
    ss.s_name,
    os.total_value,
    RANK() OVER (PARTITION BY ss.s_suppkey ORDER BY os.total_value DESC) AS sales_rank,
    CASE 
        WHEN os.total_lines > 10 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM EligibleParts es
JOIN RankedSuppliers ss ON ss.rank <= 5
FULL OUTER JOIN OrderSummary os ON os.total_value IS NOT NULL
WHERE es.aggregate_cost > (SELECT AVG(ps.ps_supplycost) FROM partsupp ps)
AND (ss.s_acctbal IS NULL OR ss.s_acctbal > 1000)
ORDER BY es.p_name, sales_rank;
