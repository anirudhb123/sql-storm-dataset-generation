WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
), TotalOrders AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
), HighSpenders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(t.total_spent, 0) AS total_spent
    FROM customer c
    LEFT JOIN TotalOrders t ON c.c_custkey = t.o_custkey
    WHERE COALESCE(t.total_spent, 0) > 100000
), PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COUNT(*) AS total_suppliers
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
    HAVING COUNT(*) > 2
)
SELECT 
    p.p_name,
    CASE 
        WHEN r.rnk = 1 THEN 'Top Supplier'
        ELSE 'Other Suppliers'
    END AS supplier_type,
    hs.c_name AS high_spender_name,
    pd.total_suppliers,
    IFNULL(r.s_name, 'No Supplier Available') AS supplier_name,
    pd.p_retailprice,
    ROUND(pd.p_retailprice * 0.9, 2) AS discounted_price
FROM PartDetails pd
LEFT JOIN RankedSuppliers r ON pd.p_partkey = r.ps_partkey AND r.rnk = 1
LEFT JOIN HighSpenders hs ON hs.total_spent > pd.p_retailprice
WHERE pd.p_retailprice IS NOT NULL OR pd.p_retailprice > 0
ORDER BY pd.total_suppliers DESC, pd.p_name
LIMIT 50;
