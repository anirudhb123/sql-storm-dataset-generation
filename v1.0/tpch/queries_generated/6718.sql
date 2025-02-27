WITH RegionSummary AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
CustomerSummary AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        AVG(c.c_acctbal) AS avg_account_balance
    FROM customer c
    GROUP BY c.c_nationkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    rs.region_name,
    rs.nation_count,
    rs.total_supplier_balance,
    cs.customer_count,
    cs.avg_account_balance,
    od.o_orderkey,
    od.o_orderdate,
    od.total_revenue
FROM RegionSummary rs
JOIN CustomerSummary cs ON cs.c_nationkey IN (SELECT DISTINCT n.n_nationkey FROM nation n WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = rs.region_name))
JOIN OrderDetails od ON od.o_orderdate >= '2023-01-01' AND od.o_orderdate < '2024-01-01'
ORDER BY rs.region_name, cs.customer_count DESC, od.total_revenue DESC;
