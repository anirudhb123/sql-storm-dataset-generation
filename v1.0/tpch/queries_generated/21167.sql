WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           COUNT(DISTINCT ps.ps_partkey) AS available_parts,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_nation
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F') -- Only open and finished orders
    GROUP BY c.c_custkey
),
OutOfStockParts AS (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_availqty = 0
),
SupplierSelection AS (
    SELECT rs.s_suppkey, 
           rs.available_parts,
           COALESCE(c.total_spent / NULLIF(rs.total_supply_cost, 0), 0) AS cost_efficiency
    FROM RankedSuppliers rs
    LEFT JOIN CustomerOrders c ON rs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = 
               (SELECT p.p_partkey FROM part p ORDER BY p.p_retailprice DESC LIMIT 1) LIMIT 1)
    WHERE rs.available_parts > 0
)
SELECT s.s_suppkey,
       s.s_name,
       s.s_address,
       CASE 
           WHEN ss.rank_within_nation <= 3 THEN 'Top Supplier'
           ELSE 'Regular Supplier'
       END AS supplier_rank,
       COALESCE(ss.cost_efficiency, 0) AS cost_efficiency,
       STRING_AGG(DISTINCT CAST(ps.ps_partkey AS TEXT), ', ') AS part_keys
FROM supplier s
JOIN SupplierSelection ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
WHERE ps.ps_partkey NOT IN (SELECT p.p_partkey FROM part p WHERE p.p_size >= 100) 
OR ps.ps_partkey IS NULL
GROUP BY s.s_suppkey, s.s_name, s.s_address, ss.rank_within_nation, ss.cost_efficiency
HAVING COUNT(DISTINCT ps.ps_partkey) > 0
ORDER BY cost_efficiency DESC, supplier_rank;
