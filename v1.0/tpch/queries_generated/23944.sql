WITH RecursiveSupplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
), 
PartSupplier AS (
    SELECT ps.ps_partkey, p.p_name, ps.ps_availqty, 
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) as supp_rank
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100)
), 
OrdersDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           DENSE_RANK() OVER (ORDER BY o.o_orderdate) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N' AND l.l_shipmode = 'AIR'
    GROUP BY o.o_orderkey, o.o_totalprice
)

SELECT 
    r.r_name, 
    MAX(COALESCE(ps.ps_availqty, 0)) AS Max_Avail_Qty,
    COUNT(DISTINCT CASE WHEN os.revenue IS NOT NULL THEN os.o_orderkey END) AS Order_Count,
    SUM(CASE 
            WHEN os.o_totalprice > 1000 
            THEN os.o_totalprice 
            ELSE 0 
        END) AS Sum_Above_1000,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_acctbal, ')'), '; ') AS Supplier_Info
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN RecursiveSupplier s ON n.n_nationkey = s.s_nationkey AND s.rank = 1
LEFT JOIN PartSupplier ps ON ps.ps_partkey = (
        SELECT p_partkey FROM part 
        WHERE p_name LIKE 'Part%') 
LEFT JOIN OrdersDetails os ON os.o_orderkey IN (
    SELECT o_orderkey 
    FROM orders 
    WHERE o_orderstatus IN ('F', 'P') 
    AND o_orderdate > (CURRENT_DATE - INTERVAL '1 year')
)
WHERE s.s_acctbal IS NOT DISTINCT FROM NULL
GROUP BY r.r_name
HAVING COUNT(s.s_suppkey) > 5 
   OR MAX(COALESCE(ps.ps_availqty, 0)) > 100
ORDER BY r.r_name DESC
LIMIT 25 OFFSET (SELECT COUNT(DISTINCT n_name) FROM nation) % 10;
