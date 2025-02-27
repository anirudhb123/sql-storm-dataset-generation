WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_size,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, p.p_size
    HAVING AVG(ps.ps_supplycost) < 1000.00
),
TopRegions AS (
    SELECT 
        n.n_regionkey, 
        r.r_name,
        SUM(o.o_totalprice) AS region_revenue
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_regionkey, r.r_name
    ORDER BY region_revenue DESC
    LIMIT 5
)
SELECT 
    cs.c_name,
    tp.p_name,
    tp.p_retailprice,
    rs.s_name AS supplier_name,
    tr.r_name AS region_name,
    cs.total_orders,
    cs.total_spent,
    rs.s_acctbal,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        ELSE CAST(cs.total_spent AS varchar)
    END AS total_spent_display
FROM CustomerOrders cs
LEFT JOIN HighValueParts tp ON cs.total_spent > tp.p_retailprice
LEFT JOIN RankedSuppliers rs ON rs.rn = 1 AND rs.s_nationkey = cs.c_custkey
JOIN TopRegions tr ON tr.region_revenue > 50000
WHERE 
    cs.total_orders > 0 OR cs.total_spent IS NULL
ORDER BY cs.total_spent DESC, tp.p_retailprice;
