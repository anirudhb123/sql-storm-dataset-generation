WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderpriority = 'High'
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_supply, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01' OR o.o_orderdate IS NULL
    GROUP BY c.c_custkey, c.c_name
),
CombinedInfo AS (
    SELECT DISTINCT 
        ch.o_orderkey,
        ch.o_orderdate,
        cs.c_name,
        ps.total_supply,
        pd.p_name,
        pd.price_rank
    FROM OrderHierarchy ch
    LEFT JOIN CustomerOrders cs ON ch.o_orderkey = cs.c_custkey
    LEFT JOIN SupplierStats ps ON ch.o_orderkey = ps.s_suppkey
    LEFT JOIN PartDetails pd ON ch.o_orderkey = pd.p_partkey
)
SELECT * 
FROM CombinedInfo
WHERE price_rank <= 3 
AND total_supply IS NOT NULL 
ORDER BY o_orderdate DESC, total_supply DESC;
