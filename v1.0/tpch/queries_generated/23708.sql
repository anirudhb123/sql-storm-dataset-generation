WITH RecursiveSupplier AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS rec_level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, rs.rec_level + 1
    FROM supplier s
    JOIN RecursiveSupplier rs ON s.s_suppkey = rs.s_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
AggregatedValues AS (
    SELECT MAX(p.p_retailprice) AS max_price,
           MIN(ps.ps_supplycost) AS min_cost,
           SUM(l.l_quantity) FILTER (WHERE l.l_discount > 0) AS total_discounted_quantity,
           COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY p.p_partkey
),
FilteredNations AS (
    SELECT DISTINCT n.n_name
    FROM nation n 
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'A%')
)
SELECT 
    COALESCE(rs.s_name, 'Unknown Supplier') AS supplier_name,
    av.max_price,
    av.min_cost,
    av.total_discounted_quantity,
    av.unique_customers,
    COUNT(DISTINCT fn.n_name) AS nation_count
FROM RecursiveSupplier rs
FULL OUTER JOIN AggregatedValues av ON rs.s_suppkey = av.max_price
LEFT JOIN FilteredNations fn ON fn.n_name LIKE '%land%'
WHERE av.total_discounted_quantity IS NOT NULL
GROUP BY rs.s_name, av.max_price, av.min_cost
HAVING AVG(rs.s_acctbal) > (SELECT SUM(ps_availqty) FROM partsupp)
ORDER BY nation_count DESC, max_price DESC;
