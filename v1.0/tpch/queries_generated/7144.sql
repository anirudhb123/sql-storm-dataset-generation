WITH SupplierAggregate AS (
    SELECT s_nationkey, SUM(s_acctbal) AS total_acctbal
    FROM supplier
    GROUP BY s_nationkey
),
PartSupplyDetails AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, ps.ps_comment, s.s_nationkey
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_totalprice
),
NationPerformance AS (
    SELECT n.n_nationkey, n.n_name, SUM(o.total_revenue) AS total_sales
    FROM nation n
    JOIN OrderSummary o ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey IN 
             (SELECT ps.ps_suppkey FROM partsupp ps JOIN PartSupplyDetails pd ON pd.p_partkey = ps.ps_partkey
              WHERE pd.p_name LIKE 'Widget%'))
    GROUP BY n.n_nationkey, n.n_name
)
SELECT n.n_name, COALESCE(sp.total_acctbal, 0) AS total_supplier_acctbal, np.total_sales
FROM NationPerformance np
JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = np.n_nationkey)
LEFT JOIN SupplierAggregate sp ON sp.s_nationkey = np.n_nationkey
WHERE np.total_sales > 1000000
ORDER BY np.total_sales DESC, total_supplier_acctbal DESC;
