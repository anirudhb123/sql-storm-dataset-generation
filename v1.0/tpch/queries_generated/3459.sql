WITH SupplierCost AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost 
    FROM partsupp ps 
    GROUP BY ps.ps_partkey
),
OrderSummary AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price, 
           COUNT(l.l_orderkey) AS line_count
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
    GROUP BY o.o_orderkey
),
CustomerAggregate AS (
    SELECT c.c_custkey, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, ca.total_spent, ca.order_count
    FROM customer c 
    JOIN CustomerAggregate ca ON c.c_custkey = ca.c_custkey 
    WHERE ca.total_spent > 10000
),
PartDetails AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_retailprice, 
           COALESCE(sc.total_supply_cost, 0) AS supply_cost
    FROM part p 
    LEFT JOIN SupplierCost sc ON p.p_partkey = sc.ps_partkey
)
SELECT hv.c_custkey, 
       hv.c_name,
       pd.p_partkey,
       pd.p_name,
       pd.p_retailprice - pd.supply_cost AS profit_margin,
       os.line_count,
       os.total_price,
       CASE 
           WHEN os.total_price > 1000 THEN 'High Value Order' 
           ELSE 'Standard Order' 
       END AS order_category,
       ROW_NUMBER() OVER (PARTITION BY hv.c_custkey ORDER BY os.total_price DESC) as order_rank
FROM HighValueCustomers hv 
JOIN OrderSummary os ON hv.c_custkey = os.o_orderkey
JOIN PartDetails pd ON pd.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = os.o_orderkey)
WHERE pd.p_retailprice IS NOT NULL
ORDER BY hv.c_custkey, order_rank;
