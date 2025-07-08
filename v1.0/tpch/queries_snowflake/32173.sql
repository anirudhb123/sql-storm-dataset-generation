
WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, 1 AS HierarchyLevel
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, oh.HierarchyLevel + 1
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderdate < DATEADD(day, -30, '1998-10-01'::date)
        AND o.o_orderstatus IN ('F', 'P')
),
SupplierAggregate AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS TotalAvailableQty, 
           AVG(ps.ps_supplycost) AS AvgSupplyCost,
           COUNT(DISTINCT ps.ps_suppkey) AS SupplierCount
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
NationAggregates AS (
    SELECT n.n_nationkey, n.n_name, SUM(s.s_acctbal) AS TotalAcctBal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
CustomerOrderInfo AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS TotalSpent,
           COUNT(o.o_orderkey) AS TotalOrders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT ph.p_partkey, ph.p_name, ph.p_retailprice, sa.TotalAvailableQty, 
       na.TotalAcctBal, ca.TotalSpent, 
       RANK() OVER (PARTITION BY ph.p_partkey ORDER BY sa.TotalAvailableQty DESC, na.TotalAcctBal ASC) AS RankValue
FROM part ph
LEFT JOIN SupplierAggregate sa ON ph.p_partkey = sa.ps_partkey
LEFT JOIN NationAggregates na ON sa.ps_partkey = na.n_nationkey
LEFT JOIN CustomerOrderInfo ca ON ph.p_partkey = ca.c_custkey
WHERE ph.p_size > 15 AND 
      (sa.TotalAvailableQty IS NOT NULL AND na.TotalAcctBal IS NOT NULL)
ORDER BY RankValue, ph.p_partkey DESC
LIMIT 100;
