WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS ranking,
        n.n_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL AND SUM(o.o_totalprice) > 1000
),
PartSupplierInformation AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment,
        AVG(ps.ps_supplycost) OVER (PARTITION BY p.p_partkey) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    hvc.c_custkey,
    hvc.c_name,
    rs.s_name AS top_supplier,
    psi.p_partkey,
    psi.p_name,
    psi.ps_availqty AS available_quantity,
    psi.ps_supplycost,
    CASE 
        WHEN hvc.total_spent > 5000 THEN 'High Spender' 
        ELSE 'Regular Spender' 
    END AS customer_type,
    (CASE WHEN PSI.ps_supplycost < 10 
          THEN 'Budget' 
          ELSE 'Premium' 
          END) AS supply_cost_category,
    STRING_AGG(DISTINCT rs.n_name, ', ') AS supplier_nations
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    RankedSuppliers rs ON hvc.c_custkey = rs.s_suppkey AND rs.ranking = 1
JOIN 
    PartSupplierInformation psi ON psi.ps_availqty > 0
WHERE 
    psi.avg_supply_cost IS NOT NULL
    AND psi.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
GROUP BY 
    hvc.c_custkey, hvc.c_name, rs.s_name, psi.p_partkey, psi.p_name, psi.ps_availqty, psi.ps_supplycost, hvc.total_spent
ORDER BY 
    hvc.total_spent DESC, hvc.c_name;
