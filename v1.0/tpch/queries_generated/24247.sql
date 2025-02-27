WITH RankedSuppliers AS (
    SELECT s_suppkey, s_name, s_nationkey,
           RANK() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) as rank
    FROM supplier
),
SubqueryLineItem AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM lineitem
    WHERE l_shipdate < CURRENT_DATE - INTERVAL '30 days'
    GROUP BY l_orderkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate,
           SUBSTRING(o.o_comment FROM 1 FOR 10) AS short_comment
    FROM orders o
    WHERE o.o_totalprice > (
        SELECT AVG(o2.o_totalprice) FROM orders o2
        WHERE o2.o_orderdate BETWEEN (CURRENT_DATE - INTERVAL '1 year') 
        AND (CURRENT_DATE)
    )
),
CombinedData AS (
    SELECT n.n_nationkey, n.n_name, 
           COUNT(DISTINCT c.c_custkey) AS customer_count,
           SUM(ps.ps_supplycost) AS total_supply_cost,
           COALESCE(SUM(r.s_total), 0) AS revenue,
           CASE WHEN COUNT(DISTINCT c.c_custkey) > 0 THEN 
                SUM(CASE WHEN ls.l_returnflag = 'R' THEN 1 ELSE 0 END)
           ELSE 
                NULL END AS return_count
    FROM nation n
    LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
    LEFT JOIN partsupp ps ON ps.ps_suppkey = c.c_custkey
    LEFT JOIN (
        SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS s_total
        FROM lineitem
        GROUP BY l_orderkey
    ) AS ls ON ls.l_orderkey = ps.ps_partkey
    LEFT JOIN RankedSuppliers rs ON rs.s_nationkey = n.n_nationkey
    WHERE n.n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE '%East%')
    GROUP BY n.n_nationkey, n.n_name
)
SELECT cd.n_nationkey, cd.n_name, cd.customer_count, cd.total_supply_cost, cd.revenue, 
       (SELECT COUNT(DISTINCT o_orderkey) 
        FROM HighValueOrders ho 
        WHERE ho.o_orderkey = cd.customer_count) AS high_value_orders
FROM CombinedData cd
WHERE cd.total_supply_cost IS NOT NULL
ORDER BY cd.revenue DESC NULLS LAST;
