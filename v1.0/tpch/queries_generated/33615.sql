WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
    
    UNION ALL
    
    SELECT 
        sc.s_suppkey,
        sc.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM SupplyChain sc
    JOIN partsupp ps ON sc.p_partkey = ps.ps_partkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0 AND sc.s_suppkey <> ps.ps_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartAggregation AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity,
        AVG(ps.ps_supplycost) AS average_supplycost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    r.r_name,
    co.c_name,
    pa.p_name,
    pa.total_quantity,
    pa.average_supplycost,
    co.total_spent,
    CASE WHEN pa.total_quantity IS NULL THEN 'No Sales' 
         ELSE CONCAT('Total Quantity: ', pa.total_quantity) END AS quantity_status
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN PartAggregation pa ON co.order_count > 0 AND pa.total_quantity IS NOT NULL
WHERE co.total_spent > 1000 OR pa.average_supplycost IS NULL
ORDER BY r.r_name, co.total_spent DESC;
