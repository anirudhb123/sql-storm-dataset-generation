WITH RegionSummary AS (
    SELECT r.r_name,
           COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_acctbal
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),

CustomerOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),

PartSupplierStats AS (
    SELECT p.p_partkey,
           p.p_name,
           AVG(ps.ps_supplycost) AS avg_supplycost,
           SUM(ps.ps_availqty) AS total_availqty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),

OrderLineDetails AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_linenumber) AS lineitem_count,
           SUM(l.l_quantity) AS total_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
)

SELECT r.r_name,
       rs.nation_count,
       rs.total_acctbal,
       c.c_name,
       c.order_count,
       c.total_spent,
       p.p_name,
       ps.avg_supplycost,
       ps.total_availqty,
       ol.total_revenue,
       ol.lineitem_count,
       ol.total_quantity
FROM RegionSummary rs
FULL OUTER JOIN CustomerOrders c ON rs.nation_count > 5 AND c.order_count > 10
FULL OUTER JOIN PartSupplierStats ps ON c.total_spent > ps.avg_supplycost * 100
FULL OUTER JOIN OrderLineDetails ol ON ol.lineitem_count > 1
WHERE rs.total_acctbal IS NOT NULL OR c.total_spent IS NULL
ORDER BY rs.r_name, c.c_name, p.p_name;
