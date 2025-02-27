WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
  
    UNION ALL
  
    SELECT o.orderkey, o.custkey, o.orderdate, o.totalprice, oh.level + 1
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
PartSupplierStats AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_availqty, 
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerRegion AS (
    SELECT 
        c.c_custkey, 
        n.n_nationkey, 
        r.r_regionkey,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY c.c_acctbal DESC) AS rn
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
TopCustomers AS (
    SELECT 
        cr.c_custkey,
        cr.n_nationkey,
        COUNT(o.o_orderkey) AS order_count
    FROM CustomerRegion cr
    LEFT JOIN orders o ON cr.c_custkey = o.o_custkey
    WHERE cr.rn <= 10
    GROUP BY cr.c_custkey, cr.n_nationkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    ps.total_availqty,
    ps.avg_supplycost,
    COALESCE(tc.order_count, 0) AS customer_order_count,
    CASE 
        WHEN ps.total_availqty IS NULL THEN 'No Supply'
        WHEN ps.avg_supplycost > 100 THEN 'High Cost'
        ELSE 'Available'
    END AS supply_status
FROM part p
LEFT JOIN PartSupplierStats ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN TopCustomers tc ON tc.n_nationkey = p.p_partkey -- Assuming mapping from part key to nation key for demonstration
WHERE p.p_retailprice > 50
ORDER BY p.p_partkey, supply_status, customer_order_count DESC;
