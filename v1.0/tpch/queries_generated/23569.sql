WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_acctbal, 0 AS level
    FROM customer
    WHERE c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON ch.custkey = c.c_custkey
    WHERE c.c_acctbal < ch.c_acctbal
),
TotalSales AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
SupplierCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rnk
    FROM part p
),
RegionSales AS (
    SELECT 
        r.r_name,
        SUM(ts.total_sales) AS region_total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN TotalSales ts ON ps.ps_partkey = ts.o_orderkey
    GROUP BY r.r_name
)
SELECT 
    ch.c_name,
    ps.ps_partkey,
    ps.supplier_count,
    rs.region_total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returns,
    (SELECT MAX(rnk) FROM RankedParts rp WHERE rp.p_partkey = ps.ps_partkey) AS max_rank
FROM CustomerHierarchy ch
LEFT JOIN partsupp ps ON ps.ps_availqty > 0
LEFT JOIN TotalSales ts ON ts.o_orderkey = ps.ps_partkey
LEFT JOIN orders o ON o.o_orderkey = ts.o_orderkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN RegionSales rs ON rs.r_name = (SELECT r.r_name FROM region r JOIN nation n ON r.r_regionkey = n.n_regionkey WHERE n.n_nationkey = ch.c_custkey)
GROUP BY ch.c_name, ps.ps_partkey, ps.supplier_count, rs.region_total_sales
HAVING SUM(l.l_extendedprice) IS NOT NULL AND ch.level > 0
ORDER BY region_total_sales DESC, order_count DESC;
