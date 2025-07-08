WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus,
           1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus,
           oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'O' AND oh.level < 5
),
SupplierAgg AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type,
           p.p_retailprice, COALESCE(sa.total_cost, 0) AS supply_cost
    FROM part p
    LEFT JOIN SupplierAgg sa ON p.p_partkey = sa.ps_partkey
),
CustomerRanked AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE NULL END) AS max_returned_price,
    AVG(CASE WHEN c.rank <= 5 THEN c.c_acctbal ELSE NULL END) AS avg_top_customers_balance,
    SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS discounted_sales
FROM PartSupplier p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN CustomerRanked c ON o.o_custkey = c.c_custkey
GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
HAVING SUM(l.l_quantity) > 100 AND COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY avg_top_customers_balance DESC, discounted_sales DESC;
