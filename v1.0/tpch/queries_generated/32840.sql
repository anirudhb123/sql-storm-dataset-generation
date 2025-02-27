WITH RECURSIVE SupplierChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, p.p_partkey, p.p_name
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, p.p_partkey, p.p_name
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN SupplierChain sc ON s.s_suppkey = sc.s_suppkey
    WHERE sc.s_acctbal > 50000
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
CustomerRank AS (
    SELECT c.c_custkey, ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
)
SELECT 
    r.r_name,
    COUNT(DISTINCT sc.s_suppkey) AS number_of_suppliers,
    SUM(od.total_sales) AS total_order_value,
    AVG(sc.s_acctbal) AS avg_supplier_balance,
    MAX(pr.p_retailprice) AS max_retail_price
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier sc ON sc.s_nationkey = n.n_nationkey
LEFT JOIN OrderDetails od ON od.total_sales > 1000
LEFT JOIN part pr ON pr.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 10)
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
ORDER BY total_order_value DESC
LIMIT 10;
