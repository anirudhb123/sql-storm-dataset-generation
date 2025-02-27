WITH RECURSIVE CustomerCTE AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS Level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(ca.c_acctbal) FROM customer ca)
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_acctbal, cc.Level + 1
    FROM customer c
    JOIN CustomerCTE cc ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    WHERE cc.Level < 5
),
SalesData AS (
    SELECT o.o_orderkey, o.o_totalprice, l.l_returnflag, SUM(l.l_extendedprice * (1 - l.l_discount)) AS NetRevenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate >= '2023-01-01' 
    GROUP BY o.o_orderkey, o.o_totalprice, l.l_returnflag
),
RankedSales AS (
    SELECT sd.*, 
           RANK() OVER (PARTITION BY sd.l_returnflag ORDER BY sd.NetRevenue DESC) AS SalesRank
    FROM SalesData sd
),
SupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
FinalData AS (
    SELECT cte.c_custkey, cte.c_name, ss.TotalSupplyCost, rs.NetRevenue
    FROM CustomerCTE cte
    LEFT JOIN RankedSales rs ON cte.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = rs.o_orderkey)
    LEFT JOIN SupplierStats ss ON ss.ps_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = rs.o_orderkey LIMIT 1)
)
SELECT *
FROM FinalData
WHERE (TotalSupplyCost IS NOT NULL OR NetRevenue IS NOT NULL)
ORDER BY c_custkey, TotalSupplyCost DESC NULLS LAST;
