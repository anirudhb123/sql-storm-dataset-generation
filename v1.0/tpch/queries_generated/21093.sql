WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS balance_rank
    FROM supplier s
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name,
           CASE 
               WHEN p.p_retailprice IS NULL THEN 0
               ELSE p.p_retailprice
           END AS adjusted_price,
           p.p_brand
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 20 AND 
          p.p_type LIKE '%widget%'
)
SELECT 
    c.c_name AS customer_name,
    c.c_acctbal AS customer_balance,
    n.n_name AS nation_name,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) END), 0) AS total_returned,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(fp.adjusted_price) AS average_part_price,
    COUNT(DISTINCT CASE WHEN rs.balance_rank = 1 THEN rs.s_suppkey END) AS top_supplier_count
FROM customer c
JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
JOIN FilteredParts fp ON l.l_partkey = fp.p_partkey
WHERE c.c_acctbal > (
        SELECT AVG(c2.c_acctbal) 
        FROM customer c2 
        WHERE c2.c_nationkey = c.c_nationkey
    )
GROUP BY c.c_name, c.c_acctbal, n.n_name
HAVING MAX(fp.adjusted_price) < 1000.00
ORDER BY customer_balance DESC, nation_name ASC;
