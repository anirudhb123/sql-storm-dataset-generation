WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        1 AS level
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01' 

    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.level < 5
),

SupplierPart AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),

TopNations AS (
    SELECT 
        n.n_name,
        SUM(s.s_acctbal) AS total_balance
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey
    ORDER BY total_balance DESC
    LIMIT 5
)

SELECT 
    p.p_name,
    p.p_container,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS revenue,
    STRING_AGG(DISTINCT tn.n_name, ', ') AS top_nations,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY revenue DESC) AS rank
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN SupplierPart sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN TopNations tn ON tn.n_nationkey IN (
    SELECT DISTINCT s.s_nationkey 
    FROM supplier s 
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    WHERE ps.ps_partkey = p.p_partkey
)
WHERE p.p_retailprice > 50.00
GROUP BY p.p_partkey
HAVING revenue > 1000.00
ORDER BY revenue DESC;
