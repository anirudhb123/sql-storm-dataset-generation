WITH RECURSIVE PartRevenue AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY p.p_partkey
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        COALESCE(NULLIF(s.s_name, ''), 'Unknown Supplier') AS supplier_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopParts AS (
    SELECT 
        p.p_partkey,
        RANK() OVER (ORDER BY pr.total_revenue DESC) AS revenue_rank
    FROM part p
    JOIN PartRevenue pr ON p.p_partkey = pr.p_partkey
    WHERE pr.total_revenue > (
        SELECT AVG(total_revenue) 
        FROM PartRevenue
        WHERE p_partkey IS NOT NULL
    )
)
SELECT 
    t.p_partkey,
    COALESCE(s.supplier_name, 'No Supplier') AS supplier_name,
    t.revenue_rank,
    CASE 
        WHEN t.revenue_rank <= 10 THEN 'Top Performer'
        WHEN t.revenue_rank <= 20 THEN 'Average Performer'
        ELSE 'Low Performer'
    END AS performance_category,
    IFNULL(s.supply_cost, 0) AS total_supply_cost,
    CONCAT('Part:', t.p_partkey, ' - Revenue Rank: ', t.revenue_rank) AS part_summary
FROM TopParts t
LEFT JOIN SupplierInfo s ON t.p_partkey = s.s_suppkey
WHERE EXISTS (
    SELECT 1 
    FROM lineitem l 
    WHERE l.l_partkey = t.p_partkey 
    AND l.l_returnflag = 'R'
) OR NOT EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.o_orderkey = (
        SELECT MAX(o2.o_orderkey) 
        FROM orders o2 
        JOIN lineitem l2 ON o2.o_orderkey = l2.l_orderkey 
        WHERE l2.l_partkey = t.p_partkey
    )
)
ORDER BY performance_category DESC, t.p_partkey ASC;
