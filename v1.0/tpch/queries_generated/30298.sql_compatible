
WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost, 1 AS depth
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    UNION ALL
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost, sc.depth + 1
    FROM SupplyChain sc
    JOIN partsupp ps ON sc.ps_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE sc.depth < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31' AND o.o_orderstatus = 'O'
),
AggregatedSales AS (
    SELECT 
        co.c_custkey,
        SUM(co.o_totalprice) AS total_sales,
        COUNT(co.o_orderkey) AS order_count
    FROM CustomerOrders co
    GROUP BY co.c_custkey
),
SalesRanked AS (
    SELECT 
        a.c_custkey,
        a.total_sales,
        a.order_count,
        RANK() OVER (ORDER BY a.total_sales DESC) AS sales_rank
    FROM AggregatedSales a
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        SUM(ps.ps_availqty) AS total_available,
        MAX(ps.ps_supplycost) AS max_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    psi.p_name AS part_name,
    psi.total_available,
    psi.max_supplycost,
    sr.total_sales,
    sr.order_count,
    sr.sales_rank
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN SupplyChain sc ON n.n_nationkey = sc.s_suppkey
JOIN PartSupplierInfo psi ON sc.ps_partkey = psi.p_partkey
JOIN SalesRanked sr ON sr.c_custkey = sc.s_suppkey
WHERE psi.total_available IS NOT NULL
ORDER BY sr.sales_rank, psi.max_supplycost DESC;
