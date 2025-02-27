WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
  
    UNION ALL

    SELECT s2.s_suppkey, s2.s_name, s2.s_acctbal, s2.s_nationkey, sh.level + 1
    FROM supplier s2
    JOIN SupplierHierarchy sh ON s2.s_nationkey = sh.s_nationkey
    WHERE s2.s_acctbal > sh.s_acctbal AND sh.level < 5
),
PartAvailability AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerTopSpenders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, RANK() OVER (ORDER BY c.c_acctbal DESC) AS spend_rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(av.total_available, 0) AS total_available,
    RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS nation_order_rank,
    cts.c_name AS top_spender_name,
    cts.c_acctbal AS top_spender_balance
FROM 
    part p
LEFT JOIN 
    PartAvailability av ON p.p_partkey = av.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
CROSS JOIN 
    CustomerTopSpenders cts
WHERE 
    l.l_shipdate > '2023-01-01'
    AND p.p_retailprice <= (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2 
        WHERE p2.p_size > 10
    )
    AND (p.p_mfgr LIKE '%Manufacturer%' OR p.p_brand IS NULL)
GROUP BY 
    p.p_partkey, p.p_name, p.p_retailprice, av.total_available, cts.c_name, cts.c_acctbal, n.n_nationkey
ORDER BY 
    p.p_partkey, nation_order_rank;
