WITH RECURSIVE OrderCTE AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS Depth
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
    UNION ALL
    SELECT o.orderkey, o.custkey, o.orderdate, o.totalprice, Depth + 1
    FROM orders o
    JOIN OrderCTE cte ON o.o_custkey = cte.o_custkey
    WHERE o.o_orderdate > cte.o_orderdate
      AND Depth < 5
),
Nations AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
SupplierSummary AS (
    SELECT s.s_nationkey, COUNT(DISTINCT s.s_suppkey) AS num_suppliers, AVG(s.s_acctbal) AS avg_acctbal
    FROM supplier s
    GROUP BY s.s_nationkey
),
PartSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
LineItemAggregate AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01' 
      AND l.l_shipdate < CURRENT_DATE
    GROUP BY l.l_orderkey
)
SELECT 
    o.o_orderkey, 
    o.o_totalprice, 
    o.o_orderdate,
    nn.n_name AS nation_name,
    ps_partkey, 
    p.p_name, 
    COALESCE(ps.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(l.total_revenue, 0) AS total_revenue,
    COUNT(cte.Depth) AS order_count
FROM OrderCTE o
LEFT JOIN Customer c ON o.o_custkey = c.c_custkey
LEFT JOIN Nations nn ON c.c_nationkey = nn.n_nationkey
LEFT JOIN PartSupplier ps ON ps.ps_partkey = (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    JOIN part p ON p.p_partkey = ps.ps_partkey 
    WHERE p.p_brand = 'Brand#23'
    ORDER BY ps.ps_supplycost DESC
    LIMIT 1
)
LEFT JOIN LineItemAggregate l ON l.l_orderkey = o.o_orderkey
WHERE o.o_totalprice > (
    SELECT AVG(o2.o_totalprice) 
    FROM orders o2 
    WHERE o2.o_orderdate < o.o_orderdate
)
AND o.o_orderstatus <> 'F'
GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate, nn.n_name, ps_partkey, p.p_name
ORDER BY o.o_orderdate DESC;
