WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
CustomerSpending AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
RegionSuppliers AS (
    SELECT r.r_name, SUM(sd.total_supplycost) AS total_supply_cost_per_region
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
    GROUP BY r.r_name
)
SELECT 
    ch.cust_name,
    ch.total_spent,
    COALESCE(rs.total_supply_cost_per_region, 0) AS total_supply_cost_per_region,
    ROW_NUMBER() OVER (PARTITION BY ch.total_spent ORDER BY rs.total_supply_cost_per_region DESC) AS rank
FROM 
    CustomerSpending ch
LEFT JOIN 
    RegionSuppliers rs ON ch.total_spent > rs.total_supply_cost_per_region
WHERE 
    (ch.total_spent IS NOT NULL OR ras.total_supply_cost_per_region IS NOT NULL)
ORDER BY 
    ch.total_spent DESC, rank ASC;
