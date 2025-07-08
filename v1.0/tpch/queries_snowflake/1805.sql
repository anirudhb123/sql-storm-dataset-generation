
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank,
        o.o_custkey
    FROM orders o
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey
),
HighValueSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales
    FROM SupplierSales ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE ss.total_sales > (SELECT AVG(total_sales) FROM SupplierSales)
)
SELECT 
    r.r_name,
    COUNT(DISTINCT hvs.s_suppkey) AS high_value_supplier_count,
    SUM(CASE WHEN ro.order_rank = 1 THEN ro.o_totalprice ELSE 0 END) AS highest_order_total,
    LISTAGG(DISTINCT hvs.s_name, ', ') AS high_value_suppliers
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN RankedOrders ro ON c.c_custkey = ro.o_custkey
LEFT JOIN HighValueSales hvs ON hvs.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    JOIN part p ON ps.ps_partkey = p.p_partkey 
    WHERE p.p_size > 50
)
WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
GROUP BY r.r_name
ORDER BY r.r_name;
