WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
), SupplierPartCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), ComplexAggregates AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
        AVG(s.s_acctbal) AS avg_supplier_balance,
        MAX(CASE WHEN s.s_comment LIKE '%important%' THEN s.s_acctbal ELSE NULL END) AS max_important_balance
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name
), OuterJoinExample AS (
    SELECT 
        cn.c_name,
        rn.r_name,
        coalesce(ca.total_revenue, 0) AS total_revenue,
        coalesce(spc.num_suppliers, 0) AS supplier_count
    FROM customer cn
    LEFT JOIN region rn ON cn.c_nationkey = rn.r_regionkey
    LEFT JOIN ComplexAggregates ca ON cn.c_custkey = ca.p_partkey
    LEFT JOIN SupplierPartCount spc ON cn.c_custkey = spc.ps_partkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    r.r_name AS region,
    COALESCE(MAX(e.total_revenue), 0) AS max_revenue,
    LEAD(o.o_totalprice, 1) OVER (PARTITION BY o.orderkey ORDER BY o.o_orderdate) AS next_order_value,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Finished'
        WHEN o.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Unknown' 
    END AS status_desc
FROM RankedOrders o
LEFT JOIN OuterJoinExample r ON o.o_orderkey = r.o_orderkey
LEFT JOIN ComplexAggregates e ON e.p_partkey = o.o_orderkey
GROUP BY 
    o.o_orderkey, 
    o.o_orderdate, 
    o.o_totalprice, 
    r.r_name
HAVING 
    MAX(o.o_totalprice) > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = 'F') 
    OR COUNT(e.total_revenue) IS NULL
ORDER BY o.o_orderdate DESC;
