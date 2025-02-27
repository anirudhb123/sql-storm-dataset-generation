WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
TotalLineitem AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(*) AS total_items
    FROM lineitem l
    WHERE l.l_shipdate <= cast('1998-10-01' as date)
    GROUP BY l.l_orderkey
),
CustomerNation AS (
    SELECT c.c_custkey,
           n.n_nationkey
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
),
HighValueSupplier AS (
    SELECT ps.ps_partkey,
           ps.ps_suppkey,
           ps.ps_availqty,
           ps.ps_supplycost
    FROM partsupp ps
    JOIN RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    WHERE rs.rnk <= 3
)
SELECT c.c_name,
       cn.n_nationkey,
       COALESCE(SUM(t.total_revenue), 0) AS total_revenue,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       STRING_AGG(DISTINCT CONCAT_WS(' - ', p.p_name, p.p_brand), ', ') AS part_info
FROM customer c
LEFT JOIN CustomerNation cn ON c.c_custkey = cn.c_custkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN TotalLineitem t ON o.o_orderkey = t.l_orderkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN HighValueSupplier hvs ON l.l_partkey = hvs.ps_partkey
LEFT JOIN part p ON hvs.ps_partkey = p.p_partkey
WHERE (o.o_orderstatus = 'O' OR o.o_orderstatus = 'R')
AND (c.c_acctbal > 1000 OR hvs.ps_availqty < 50)
GROUP BY c.c_name, cn.n_nationkey;