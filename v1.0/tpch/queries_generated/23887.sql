WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_name LIKE 'A%'
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_regionkey
    WHERE nh.level < 5
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_supplycost, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
),
LineItemInfo AS (
    SELECT l.l_orderkey, l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS NetPrice
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_returnflag IS NULL
    GROUP BY l.l_orderkey, l.l_partkey
)
SELECT n.n_name, 
       COALESCE(SUM(pd.p_retailprice * li.NetPrice), 0) AS TotalRetailValue,
       COUNT(DISTINCT co.c_custkey) AS ActiveCustomers,
       AVG(nh.level) AS AvgNationLevel
FROM nation n
LEFT JOIN NationHierarchy nh ON n.n_nationkey = nh.n_nationkey
LEFT JOIN PartDetails pd ON pd.p_partkey IN (SELECT p_partkey FROM part WHERE p_name LIKE '%Widget%')
LEFT JOIN LineItemInfo li ON li.l_partkey IN (SELECT p_partkey FROM part WHERE p_type = 'GADGET')
LEFT JOIN CustomerOrders co ON co.c_custkey IN (SELECT c_custkey FROM customer WHERE c_acctbal IS NOT NULL AND c_name NOT LIKE '%test%')
WHERE n.n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE 'North%')
GROUP BY n.n_name
HAVING COALESCE(AVG(pd.p_retailprice), 0) > 50 AND COUNT(DISTINCT li.l_orderkey) > 0
ORDER BY TotalRetailValue DESC
LIMIT 10 OFFSET 5;
