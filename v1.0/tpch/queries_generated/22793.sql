WITH RecursivePart AS (
    SELECT p_partkey, p_name, p_retailprice, p_comment,
           ROW_NUMBER() OVER (PARTITION BY p_mfgr ORDER BY p_retailprice DESC) AS rn
    FROM part
    WHERE p_retailprice IS NOT NULL
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
    HAVING COUNT(*) > 1
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate) AS order_rank
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o1.o_totalprice) FROM orders o1)
),
LineItemRemarks AS (
    SELECT l.l_orderkey, 
           SUM(l.l_quantity) AS total_quantity,
           MAX(l.l_discount) AS max_discount,
           SUM(CASE WHEN l.l_returnflag = 'Y' THEN l.l_extendedprice ELSE 0 END) AS return_value
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT p.p_name, 
       p.p_retailprice,
       COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
       o.o_totalprice,
       r.r_name,
       COALESCE(l.total_quantity, 0) AS total_quantity,
       COALESCE(l.return_value, 0) AS total_return_value,
       CASE WHEN l.max_discount IS NULL THEN 'No Discount' 
            ELSE CONCAT(CAST(l.max_discount * 100 AS DECIMAL(5, 2)), '% Discount') END AS discount_info 
FROM RecursivePart p
LEFT JOIN SupplierInfo s ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'ARGENTINA')
LEFT JOIN OrderSummary o ON o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
LEFT JOIN LineItemRemarks l ON l.l_orderkey = o.o_orderkey
LEFT JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = s.s_nationkey)
WHERE p.rn = 1 AND (p.p_comment LIKE '%fragile%' OR p.p_comment IS NULL)
ORDER BY p.p_retailprice DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
