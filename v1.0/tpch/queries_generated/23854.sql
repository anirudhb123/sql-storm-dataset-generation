WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part AS p
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM supplier AS s
    JOIN partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice) * (1 - AVG(l.l_discount)) AS net_revenue
    FROM orders AS o
    LEFT JOIN lineitem AS l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
    HAVING net_revenue > 10000
),
NationalStatistics AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM nation AS n
    LEFT JOIN customer AS c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN supplier AS s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    p.p_name, 
    p.p_brand, 
    n.n_name AS nation,
    COALESCE(si.total_cost, 0) AS supplier_total_cost,
    nv.customer_count,
    SUM(hv.line_count) AS total_order_lines,
    SUM(hv.o_totalprice) AS total_order_value
FROM RankedParts AS p
LEFT JOIN SupplierInfo AS si ON si.total_parts > 10 AND si.total_cost < (SELECT AVG(si2.total_cost) FROM SupplierInfo si2)
LEFT JOIN NationalStatistics AS nv ON nv.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'AFRICA')
LEFT JOIN HighValueOrders AS hv ON hv.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
WHERE p.price_rank <= 5 AND p.p_type LIKE '%BRASS%'
GROUP BY p.p_name, p.p_brand, n.n_name, si.total_cost, nv.customer_count
HAVING COUNT(DISTINCT p.p_partkey) > 0
ORDER BY total_order_value DESC NULLS LAST;
