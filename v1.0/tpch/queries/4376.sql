WITH SupplierCost AS (
    SELECT ps_partkey, ps_suppkey, SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM partsupp
    GROUP BY ps_partkey, ps_suppkey
),
RankedOrders AS (
    SELECT o_orderkey, o_totalprice, o_orderdate,
           RANK() OVER (PARTITION BY o_orderstatus ORDER BY o_totalprice DESC) AS price_rank
    FROM orders
    WHERE o_orderdate >= DATE '1996-01-01'
),
CustomerNation AS (
    SELECT c.c_custkey, c.c_name, n.n_name,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY c.c_acctbal DESC) AS cust_rank
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
)
SELECT 
    p.p_name,
    p.p_retailprice,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    COALESCE(MAX(l.l_extendedprice), 0) AS max_extended_price,
    COUNT(DISTINCT so.o_orderkey) AS order_count,
    CASE 
        WHEN r.r_name IS NOT NULL THEN 'Exists'
        ELSE 'Not Exists'
    END AS region_exists
FROM 
    part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN SupplierCost sc ON p.p_partkey = sc.ps_partkey
LEFT JOIN RankedOrders so ON l.l_orderkey = so.o_orderkey AND so.price_rank <= 5
LEFT JOIN nation n ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = sc.ps_suppkey FETCH FIRST 1 ROWS ONLY)
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 10.00
    AND EXISTS (SELECT 1 FROM CustomerNation cn WHERE cn.cust_rank = 1 AND cn.c_custkey = so.o_orderkey)
GROUP BY 
    p.p_partkey, p.p_name, p.p_retailprice, r.r_name
ORDER BY 
    total_quantity DESC, max_extended_price ASC;