WITH SupplierTotalCost AS (
    SELECT ps.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        r.r_regionkey
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_custkey, r.r_regionkey
),
PopularParts AS (
    SELECT 
        l.l_partkey,
        COUNT(*) AS order_count
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY l.l_partkey
    HAVING COUNT(*) > 10
)
SELECT 
    p.p_name,
    s.s_name,
    COALESCE(c.total_spent, 0) AS customer_spent,
    COALESCE(s.total_cost, 0) AS supplier_cost,
    pp.order_count AS parts_order_count,
    RANK() OVER (PARTITION BY s.s_suppkey ORDER BY COALESCE(s.total_cost, 0) DESC) AS supplier_rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN SupplierTotalCost stc ON s.s_suppkey = stc.s_suppkey
LEFT JOIN CustomerOrders c ON s.s_nationkey = c.r_regionkey
LEFT JOIN PopularParts pp ON p.p_partkey = pp.l_partkey
WHERE p.p_retailprice > 100.00 
AND p.p_size IS NOT NULL
ORDER BY customer_spent DESC, supplier_cost DESC;
