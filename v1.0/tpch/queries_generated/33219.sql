WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 500
    GROUP BY s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
NationAggregation AS (
    SELECT nh.n_name, COUNT(DISTINCT c.c_custkey) AS total_customers
    FROM NationHierarchy nh
    JOIN customer c ON nh.n_nationkey = c.c_nationkey
    GROUP BY nh.n_name
)
SELECT 
    p.p_name,
    p.p_type,
    p.p_size,
    COALESCE(sd.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(os.total_price, 0) AS total_order_value,
    na.total_customers AS number_of_customers,
    ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY COALESCE(sd.total_supply_cost, 0) DESC) AS rank_within_type
FROM part p
LEFT JOIN SupplierDetails sd ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey)
LEFT JOIN OrderSummary os ON p.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o))
LEFT JOIN NationAggregation na ON p.p_name LIKE '%' || na.n_name || '%'
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_type = p.p_type)
ORDER BY p.p_type, total_supply_cost DESC;
