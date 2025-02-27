WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT r.r_regionkey, r.r_name, rs.s_suppkey, rs.s_name
    FROM region r
    JOIN RankedSuppliers rs ON r.r_regionkey = (SELECT n.n_regionkey 
                                                  FROM nation n 
                                                  WHERE n.n_nationkey = 
                                                  (SELECT s.s_nationkey 
                                                   FROM supplier s 
                                                   WHERE s.s_suppkey = rs.s_suppkey))
    WHERE rs.rank <= 3
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT r.r_name AS region_name, ts.s_name AS supplier_name, pd.p_name AS part_name, 
       os.total_revenue, pd.ps_supplycost, pd.ps_availqty
FROM TopSuppliers ts
JOIN PartDetails pd ON ts.s_suppkey = pd.ps_partkey
JOIN OrderSummary os ON os.total_revenue > 10000
JOIN region r ON ts.r_regionkey = r.r_regionkey
ORDER BY os.total_revenue DESC, r.r_name, ts.s_name;
