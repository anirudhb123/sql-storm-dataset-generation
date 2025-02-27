WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, 
           RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM RankedSuppliers s
    WHERE s.rnk <= 5
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_supplycost, ps.ps_availqty,
           (p.p_retailprice - ps.ps_supplycost) AS profit_margin
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 50
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name, c.c_mktsegment,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name, c.c_mktsegment
),
FinalReport AS (
    SELECT ps.s_name AS supplier_name, pd.p_name AS part_name, 
           os.total_revenue, pd.profit_margin
    FROM TopSuppliers ps
    JOIN PartDetails pd ON ps.s_suppkey IN (
        SELECT ps_suppkey FROM partsupp WHERE ps_partkey = pd.p_partkey
    )
    JOIN OrderSummary os ON os.o_orderkey IN (
        SELECT l_orderkey FROM lineitem WHERE l_partkey = pd.p_partkey
    )
)
SELECT supplier_name, part_name, SUM(total_revenue) AS total_revenue,
       AVG(profit_margin) AS avg_profit_margin
FROM FinalReport
GROUP BY supplier_name, part_name
ORDER BY total_revenue DESC
LIMIT 10;
