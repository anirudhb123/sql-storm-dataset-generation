WITH RECURSIVE SupplierHierarchy AS (
    SELECT S.s_suppkey, S.s_name, S.s_nationkey, S.s_acctbal, 1 AS level
    FROM supplier S
    WHERE S.s_acctbal > 10000  -- Start from suppliers with a high account balance
    UNION ALL
    SELECT S.s_suppkey, S.s_name, S.s_nationkey, S.s_acctbal, SH.level + 1
    FROM supplier S
    JOIN SupplierHierarchy SH ON S.s_nationkey = SH.s_nationkey
    WHERE S.s_acctbal <= SH.s_acctbal AND SH.level < 5  -- Traverse down to find related suppliers
),
OrderStats AS (
    SELECT O.o_orderkey, SUM(L.l_extendedprice * (1 - L.l_discount)) AS total_sales
    FROM orders O
    JOIN lineitem L ON O.o_orderkey = L.l_orderkey
    WHERE O.o_orderdate >= '2021-01-01' AND O.o_orderdate < '2022-01-01'
    GROUP BY O.o_orderkey
),
AggregatedSales AS (
    SELECT COUNT(DISTINCT O.o_orderkey) AS order_count, 
           SUM(OS.total_sales) AS total_revenue
    FROM OrderStats OS
    JOIN customer C ON C.c_custkey = (SELECT O.o_custkey
                                       FROM orders O 
                                       WHERE O.o_orderkey = OS.o_orderkey)
    WHERE C.c_acctbal > 5000
)
SELECT R.r_name, 
       COUNT(DISTINCT N.n_nationkey) AS nation_count,
       SUM(AS.total_revenue) AS regional_revenue
FROM region R
JOIN nation N ON R.r_regionkey = N.n_regionkey
JOIN SupplierHierarchy SH ON N.n_nationkey = SH.s_nationkey
JOIN AggregatedSales AS ON AS.order_count > 0
GROUP BY R.r_name
ORDER BY regional_revenue DESC;
