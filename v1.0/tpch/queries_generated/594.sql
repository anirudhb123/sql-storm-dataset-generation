WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
),
SupplierSales AS (
    SELECT
        s.s_suppkey,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_cost,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey
),
Nations AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        SUM(CASE WHEN c.c_acctbal IS NULL THEN 0 ELSE c.c_acctbal END) AS total_acctbal
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
)

SELECT
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    s.total_cost,
    o.o_orderkey,
    o.o_totalprice,
    CASE 
        WHEN s.total_cost > 10000 THEN 'High Value'
        WHEN s.total_cost BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS valuation,
    RANK() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS price_rank,
    COUNT(DISTINCT o.o_orderkey) OVER (PARTITION BY n.n_name) AS total_orders
FROM Nations n
LEFT JOIN SupplierSales s ON n.n_nationkey = s.s_suppkey
LEFT JOIN RankedOrders o ON s.order_count > 0 AND s.s_suppkey = o.o_orderkey
WHERE 
    s.total_cost IS NOT NULL AND
    (o.o_orderstatus = 'O' OR o.o_orderstatus = 'F')
ORDER BY n.n_name, valuation DESC, price_rank;
