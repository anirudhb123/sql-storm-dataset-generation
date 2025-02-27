WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_acctbal, 0 AS hierarchy_level
    FROM customer
    WHERE c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.hierarchy_level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_custkey
    WHERE c.c_acctbal > 0
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           COALESCE(SUM(ps.ps_supplycost), 0) AS total_supplycost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           CASE 
               WHEN p.p_container LIKE '%BOX%' THEN 'Box'
               WHEN p.p_container LIKE '%PACK%' THEN 'Pack'
               ELSE 'Other'
           END AS container_type,
           RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
)
SELECT 
    ch.c_name AS customer_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(o.o_totalprice) AS total_spent,
    MAX(s.s_name) AS main_supplier,
    SUM(pd.p_retailprice) AS total_part_value,
    STRING_AGG(DISTINCT pd.container_type, ', ') AS containers_used,
    SUM(CASE WHEN l.l_returnflag = 'Y' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
    COUNT(DISTINCT CASE WHEN hv.rn = 1 THEN hv.o_orderkey END) AS high_value_order_count
FROM CustomerHierarchy ch
JOIN orders o ON ch.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN HighValueOrders hv ON o.o_orderkey = hv.o_orderkey
LEFT JOIN partsupp ps ON ps.ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp)
LEFT JOIN SupplierDetails s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN PartDetails pd ON ps.ps_partkey = pd.p_partkey
WHERE ch.hierarchy_level <= 2
GROUP BY ch.c_name
HAVING SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
ORDER BY total_spent DESC
LIMIT 10;
