WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank,
        p.p_partkey AS associated_partkey
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
), 
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice IS NOT NULL
    GROUP BY c.c_custkey
), 
SupplierProductStats AS (
    SELECT
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY p.p_partkey
)
SELECT 
    c.c_name, 
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    COALESCE(sp.supplier_count, 0) AS supplier_count,
    COALESCE(sp.average_supply_cost, 0) AS average_supply_cost,
    CASE 
        WHEN cd.total_spent IS NOT NULL THEN cd.total_spent
        ELSE 0 
    END AS total_spent,
    cd.order_count
FROM customer c
LEFT JOIN CustomerOrderDetails cd ON c.c_custkey = cd.c_custkey
LEFT JOIN RankedSuppliers rs ON c.c_custkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rs.associated_partkey LIMIT 1)
LEFT JOIN SupplierProductStats sp ON sp.p_partkey = rs.associated_partkey
WHERE cd.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderDetails)
ORDER BY c.c_name, supplier_count DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
