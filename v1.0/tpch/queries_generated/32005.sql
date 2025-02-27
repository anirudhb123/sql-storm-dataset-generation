WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 50000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierDetail AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    sh.s_name AS supplier_name,
    coalesce(cos.order_count, 0) AS total_orders,
    coalesce(cos.total_spent, 0.00) AS total_spent,
    pd.p_name AS part_name,
    SUM(pd.ps_availqty) AS total_available_quantity,
    AVG(pd.ps_supplycost) AS average_supply_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN 
    CustomerOrderStats cos ON sh.s_suppkey = cos.c_custkey
JOIN 
    PartSupplierDetail pd ON sh.s_suppkey = pd.ps_partkey
WHERE 
    sh.s_acctbal IS NOT NULL 
    AND pd.rank = 1 
    AND (cos.total_spent > 0 OR cos.order_count > 0)
GROUP BY 
    r.r_name, n.n_name, sh.s_name, cos.order_count, cos.total_spent, pd.p_name
HAVING 
    SUM(pd.ps_availqty) > 100
ORDER BY 
    region_name, nation_name, supplier_name;
