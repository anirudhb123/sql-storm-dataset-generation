WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
),
SubqueryTotal AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    GROUP BY l.l_orderkey
),
NationalSales AS (
    SELECT 
        n.n_name,
        SUM(st.total_sales) AS total_national_sales
    FROM nation n
    JOIN (
        SELECT 
            c.c_nationkey, 
            so.l_orderkey,
            st.total_sales
        FROM customer c
        JOIN RankedOrders ro ON c.c_custkey = ro.o_orderkey
        JOIN SubqueryTotal st ON ro.o_orderkey = st.l_orderkey
        JOIN lineitem so ON so.l_orderkey = ro.o_orderkey
    ) AS st ON n.n_nationkey = st.c_nationkey
    GROUP BY n.n_name
)
SELECT 
    p.p_name,
    p.p_retailprice,
    p.p_container,
    ns.total_national_sales,
    fs.s_name AS supplier_name,
    COALESCE(fs.s_acctbal, 0) AS supplier_balance,
    CASE 
        WHEN fs.s_acctbal IS NOT NULL AND fs.s_acctbal > 10000 THEN 'High'
        WHEN fs.s_acctbal IS NULL THEN 'Unknown'
        ELSE 'Low'
    END AS balance_category,
    COUNT(DISTINCT os.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT n.n_name, ', ' ORDER BY n.n_name) AS nations
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
LEFT JOIN NationalSales ns ON ns.n_nationkey = fs.s_nationkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN orders os ON l.l_orderkey = os.o_orderkey
WHERE (p.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2) OR fs.s_name IS NOT NULL)
AND (fs.s_acctbal IS NULL OR fs.s_acctbal < 50000)
GROUP BY p.p_name, p.p_retailprice, p.p_container, ns.total_national_sales, fs.s_name
HAVING COUNT(DISTINCT os.o_orderkey) > 5
ORDER BY ns.total_national_sales DESC NULLS LAST;
