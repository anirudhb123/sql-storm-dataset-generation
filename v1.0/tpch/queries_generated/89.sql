WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) IS NOT NULL
)
SELECT 
    p.p_partkey,
    p.p_name,
    r.r_name AS region_name,
    COALESCE(s1.s_name, 'No Supplier') AS top_supplier_name,
    COALESCE(s2.s_name, 'No Supplier') AS second_supplier_name,
    cp.total_spent,
    cp.order_count,
    hvp.total_supply_value
FROM part p
JOIN HighValueParts hvp ON p.p_partkey = hvp.ps_partkey
LEFT JOIN RankedSuppliers s1 ON s1.rank = 1 AND s1.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey = p.p_partkey
)
LEFT JOIN RankedSuppliers s2 ON s2.rank = 2 AND s2.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey = p.p_partkey
)
JOIN nation n ON p.p_partkey % 10 = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN CustomerOrders cp ON cp.c_custkey = (SELECT c_custkey FROM customer ORDER BY c_acctbal DESC LIMIT 1)
WHERE p.p_retailprice > (
    SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 10
) AND p.p_comment NOT LIKE '%fragile%'
ORDER BY cp.total_spent DESC, p.p_name;
