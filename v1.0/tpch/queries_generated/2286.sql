WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
PartSuppliers AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           (ps.ps_supplycost * l.l_quantity) AS total_cost,
           string_agg(s.s_name, ', ') AS supplier_names
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost
),
AggregatedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT o.*, RANK() OVER (ORDER BY o.total_revenue DESC) AS revenue_rank
    FROM AggregatedOrders o
    WHERE o.total_revenue > (
        SELECT AVG(total_revenue)
        FROM AggregatedOrders
    )
)
SELECT p.p_name, p.p_brand, p.p_type, ps.ps_supplycost, rs.s_name, to.revenue_rank
FROM part p
LEFT JOIN PartSuppliers ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rank <= 3
JOIN TopRevenueOrders to ON to.o_orderkey = ps.ps_suppkey
WHERE p.p_retailprice BETWEEN 10 AND 100
  AND (rs.s_acctbal IS NOT NULL OR p.p_comment LIKE '%quality%')
ORDER BY to.revenue_rank, ps.ps_supplycost DESC;
