WITH RecursivePart AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, p_container, p_retailprice, p_comment,
           ROW_NUMBER() OVER (PARTITION BY p_mfgr ORDER BY p_retailprice DESC) AS rn
    FROM part
    WHERE p_size > 0
), SupplierSales AS (
    SELECT ps.s_partkey, SUM(ps.ps_supplycost * l.l_quantity) AS total_cost
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.suppkey
), CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, n.n_name AS nation_name, c.c_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS nation_rank,
           MAX(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE NULL END) AS max_order_price
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, n.n_name, c.c_acctbal
), BenchmarkData AS (
    SELECT DISTINCT rp.p_partkey, rp.p_name, rp.p_retailprice, ss.total_cost,
           cd.c_name, cd.nation_name, cd.max_order_price,
           CASE 
               WHEN cd.max_order_price IS NULL THEN 'No Orders' 
               WHEN cd.max_order_price < 1000 THEN 'Low Value' 
               ELSE 'High Value' 
           END AS order_value_category
    FROM RecursivePart rp
    LEFT JOIN SupplierSales ss ON rp.p_partkey = ss.s_partkey
    LEFT JOIN CustomerDetails cd ON ss.s_partkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rp.p_partkey ORDER BY ps.ps_supplycost ASC LIMIT 1)
    WHERE rp.rn = 1 AND rp.p_retailprice IS NOT NULL
)
SELECT b.p_partkey, b.p_name, b.p_retailprice, b.total_cost, b.c_name, 
       b.nation_name, b.order_value_category, 
       COALESCE(b.max_order_price, 0) + COALESCE(SUM(b.total_cost) OVER (PARTITION BY b.c_name), 0) AS adjusted_value,
       CASE 
           WHEN b.order_value_category = 'High Value' AND b.total_cost > 500 THEN 'Flagged' 
           ELSE 'Normal' 
       END AS status
FROM BenchmarkData b
WHERE b.total_cost IS NOT NULL OR b.order_value_category = 'Low Value'
ORDER BY b.p_retailprice DESC, b.c_name ASC;
