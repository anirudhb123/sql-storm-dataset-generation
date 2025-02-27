WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           o.o_orderstatus,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rank
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(year, -1, GETDATE()) 
      AND o.o_totalprice > (
            SELECT AVG(o2.o_totalprice)
            FROM orders o2
            WHERE o2.o_orderdate >= DATEADD(year, -1, GETDATE())
        )
),
SupplierParts AS (
    SELECT ps.ps_partkey,
           SUM(ps.ps_availqty) AS total_availqty,
           SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderLineSummary AS (
    SELECT l.l_orderkey,
           COUNT(l.l_linenumber) AS total_lines,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate > l.l_commitdate
    GROUP BY l.l_orderkey
),
FilteredCustomers AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(o.o_totalprice) AS total_spending,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL
)
SELECT DISTINCT r.r_name,
                COUNT(DISTINCT c.c_custkey) AS customer_count,
                COALESCE(SUM(o.o_totalprice), 0) AS total_order_value,
                AVG(s.total_supplycost) AS avg_supply_cost,
                AVG(os.total_revenue) AS avg_order_revenue
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN FilteredCustomers c ON c.c_custkey = s.s_suppkey
LEFT JOIN RankedOrders o ON o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l)
LEFT JOIN OrderLineSummary os ON os.l_orderkey = o.o_orderkey
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 0
ORDER BY r.r_name;
