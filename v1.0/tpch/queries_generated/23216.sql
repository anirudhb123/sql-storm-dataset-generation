WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL 
      AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
    GROUP BY o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate
),
NationsWithComments AS (
    SELECT 
        n.n_nationkey, 
        n.n_name,
        CASE 
            WHEN n.n_comment IS NULL THEN 'No comment' 
            ELSE n.n_comment 
        END AS n_comment
    FROM nation n
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE '%Asia%')
)
SELECT 
    p.p_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(o.o_orderkey, -1) AS order_key,
    o.o_totalprice,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY o.o_totalprice DESC) AS order_rank,
    ns.n_name AS nation_name,
    ns.n_comment
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rnk = 1
LEFT JOIN HighValueOrders o ON ps.ps_partkey = o.o_orderkey
LEFT JOIN NationsWithComments ns ON s.s_nationkey = ns.n_nationkey
WHERE (o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31' OR o.o_orderdate IS NULL)
  AND (p.p_size IS NOT NULL OR p.p_container = 'Box')
  AND (s.s_acctbal NOT BETWEEN 1000 AND 5000 OR s.s_acctbal IS NULL)
ORDER BY p.p_partkey, supplier_name ASC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
