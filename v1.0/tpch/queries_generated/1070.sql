WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        customer.c_name,
        RANK() OVER (PARTITION BY customer.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer ON o.o_custkey = customer.c_custkey
    WHERE o.o_orderstatus = 'O'
),
SupplierPartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS supp_rank
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
)
SELECT 
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_revenue_from_returns,
    AVG(o.o_totalprice) AS avg_order_value,
    MAX(supp.p_name) AS most_expensive_part
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN RankedOrders o ON c.c_custkey = o.o_orderkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN SupplierPartDetails supp ON supp.supp_rank = 1
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING SUM(o.o_totalprice) > 10000
ORDER BY total_orders DESC;
