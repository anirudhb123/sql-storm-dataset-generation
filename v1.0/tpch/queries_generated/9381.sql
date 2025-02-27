WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, COUNT(ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
OrderStats AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_custkey
)
SELECT 
    sd.s_name AS Supplier_Name,
    nd.n_name AS Nation_Name,
    nd.region_name AS Region_Name,
    os.total_revenue AS Total_Revenue,
    os.order_count AS Order_Count,
    sd.part_count AS Total_Parts_Supplied,
    sd.s_acctbal AS Account_Balance
FROM SupplierDetails sd
JOIN NationDetails nd ON sd.s_nationkey = nd.n_nationkey
JOIN OrderStats os ON sd.s_suppkey IN (
    SELECT ps.ps_suppkey FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
)
ORDER BY Total_Revenue DESC, Supplier_Name;
