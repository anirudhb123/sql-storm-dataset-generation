WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > 1000.00
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty,
        COALESCE(rn.rn, 0) AS best_supplier_rank
    FROM part p
    LEFT JOIN RankedSuppliers rn ON p.p_partkey = rn.s_suppkey
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    c.c_name,
    SUM(psi.p_retailprice * psi.ps_availqty) AS total_inventory_value,
    c.total_spent,
    CASE 
        WHEN c.total_spent IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status,
    ROW_NUMBER() OVER (ORDER BY SUM(psi.p_retailprice * psi.ps_availqty) DESC) AS inventory_rank
FROM CustomerOrderSummary c
JOIN PartSupplierInfo psi ON psi.best_supplier_rank = 1
WHERE psi.ps_availqty > 0
GROUP BY c.c_name, c.total_spent
HAVING SUM(psi.p_retailprice * psi.ps_availqty) > 5000.00
ORDER BY inventory_rank;
