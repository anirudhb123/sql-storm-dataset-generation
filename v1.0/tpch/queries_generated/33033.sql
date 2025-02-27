WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
),
RankedSuppliers AS (
    SELECT sc.s_suppkey, sc.s_name, sc.s_acctbal, 
           SUM(sc.ps_supplycost * sc.ps_availqty) AS total_supply_cost,
           COUNT(sc.ps_partkey) AS num_parts
    FROM SupplyChain sc
    WHERE sc.rank <= 5
    GROUP BY sc.s_suppkey, sc.s_name, sc.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment, 
           SUM(o.o_totalprice) AS total_spend,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
),
SupplierNations AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
AggregatedResults AS (
    SELECT cs.c_name AS customer_name, 
           cs.total_spend, 
           sn.n_name AS nation_name, 
           ss.total_supply_cost,
           ss.num_parts
    FROM CustomerOrders cs
    JOIN SupplierNations sn ON cs.total_spend > 1000
    JOIN RankedSuppliers ss ON sn.supplier_count > 5
    WHERE cs.order_count > 10
)
SELECT ar.customer_name,
       ar.total_spend,
       ar.nation_name,
       COALESCE(ar.total_supply_cost, 0) AS total_supply_cost,
       COALESCE(ar.num_parts, 0) AS num_parts
FROM AggregatedResults ar
ORDER BY ar.total_spend DESC;
