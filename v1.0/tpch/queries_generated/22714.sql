WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
TotalLineItems AS (
    SELECT l.l_partkey,
           SUM(l.l_quantity) AS total_quantity
    FROM lineitem l
    WHERE l.l_returnflag = 'N' AND 
          l.l_shipdate >= DATE '2023-01-01' AND 
          l.l_shipdate <= DATE '2023-12-31'
    GROUP BY l.l_partkey
),
SupplierPartInfo AS (
    SELECT ps.ps_partkey,
           ps.ps_suppkey,
           ps.ps_availqty,
           ps.ps_supplycost,
           p.p_name,
           p.p_brand,
           p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS supplier_rank
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderDetails AS (
    SELECT c.c_custkey,
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > 1000
)
SELECT r.region_name,
       COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
       COALESCE(MAX(l.total_quantity), 0) AS max_quantity,
       AVG(d.total_spent) AS avg_spent_per_customer
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN RankedSuppliers s ON s.s_nationkey = n.n_nationkey AND s.rnk <= 3
LEFT JOIN TotalLineItems l ON l.l_partkey IN (SELECT ps.ps_partkey 
                                              FROM SupplierPartInfo ps 
                                              WHERE ps.ps_suppkey = s.s_suppkey 
                                                AND ps.supplier_rank <= 5)
LEFT JOIN CustomerOrderDetails d ON d.c_custkey IN (SELECT o.o_custkey 
                                                    FROM orders o 
                                                    WHERE o.o_orderstatus = 'O')
GROUP BY r.region_name
HAVING COALESCE(SUM(CASE WHEN l.total_quantity IS NULL THEN 1 ELSE 0 END), 0) < 10
   AND COUNT(DISTINCT d.c_custkey) > 5
ORDER BY unique_suppliers DESC, avg_spent_per_customer ASC;
