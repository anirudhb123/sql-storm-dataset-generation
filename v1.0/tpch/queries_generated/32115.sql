WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
AggregatedOrderData AS (
    SELECT oh.o_custkey, COUNT(oh.o_orderkey) AS total_orders, SUM(oh.o_totalprice) AS total_spent
    FROM OrderHierarchy oh
    GROUP BY oh.o_custkey
),
SupplierDetails AS (
    SELECT ps.ps_partkey, AVG(s.s_acctbal) AS avg_supplier_acctbal
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, sd.avg_supplier_acctbal
    FROM part p
    JOIN SupplierDetails sd ON p.p_partkey = sd.ps_partkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
CustomerRank AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment,
           DENSE_RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY ad.total_spent DESC) AS rank
    FROM customer c
    JOIN AggregatedOrderData ad ON c.c_custkey = ad.o_custkey
    WHERE ad.total_orders > 3
)
SELECT cr.c_name, cr.c_mktsegment, cr.rank, hvp.p_name, hvp.p_retailprice, hvp.avg_supplier_acctbal
FROM CustomerRank cr
LEFT JOIN HighValueParts hvp ON cr.rank <= 5
WHERE cr.c_mktsegment IS NOT NULL
ORDER BY cr.c_mktsegment, cr.rank, hvp.p_retailprice DESC
LIMIT 50;
