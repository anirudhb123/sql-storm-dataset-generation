WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS Level
    FROM supplier
    WHERE s_suppkey IN (SELECT DISTINCT ps_suppkey FROM partsupp WHERE ps_availqty > 0)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.Level < 5
),
OrderSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, os.TotalSpent,
           RANK() OVER (ORDER BY os.TotalSpent DESC) AS Rank
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.c_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
)
SELECT 
    p.p_name,
    p.p_mfgr,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
    r.r_name,
    n.n_name,
    COUNT(DISTINCT TOPC.c_custkey) AS CustomerCount,
    CASE 
        WHEN SUM(l.l_discount) > 0.2 THEN 'High Discount'
        WHEN SUM(l.l_discount) IS NULL THEN 'No Discounts'
        ELSE 'Normal Discount'
    END AS DiscountCategory
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN TopCustomers TOPC ON s.s_nationkey = TOPC.c_custkey
WHERE p.p_retailprice > 20.00
GROUP BY p.p_name, p.p_mfgr, r.r_name, n.n_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY Revenue DESC
LIMIT 10;
