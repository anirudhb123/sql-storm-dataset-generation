WITH SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(s.s_acctbal) AS total_account_balance,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM supplier s
    GROUP BY s.s_nationkey
), 
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY YEAR(o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate > '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
), 
NationRevenue AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(SUM(os.total_revenue), 0) AS total_nation_revenue
    FROM nation n
    LEFT JOIN OrderSummary os ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p)))
    GROUP BY n.n_nationkey, n.n_name
)

SELECT 
    r.r_name AS region_name,
    nr.n_name AS nation_name,
    ss.total_suppliers,
    ss.total_account_balance,
    nr.total_nation_revenue,
    (SELECT COUNT(*) FROM customer c WHERE c.c_nationkey = nr.n_nationkey AND c.c_acctbal > 500) AS wealthy_customers
FROM region r
JOIN nation nr ON r.r_regionkey = nr.n_regionkey
JOIN SupplierStats ss ON nr.n_nationkey = ss.s_nationkey
WHERE nr.total_nation_revenue > (SELECT AVG(total_nation_revenue) FROM NationRevenue)
ORDER BY nr.total_nation_revenue DESC, ss.total_suppliers DESC;
