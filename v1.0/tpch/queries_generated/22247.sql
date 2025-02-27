WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
), 
SupplierPartCount AS (
    SELECT 
        ps.ps_partkey, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
NationWithParts AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        n.n_nationkey, n.n_name
)

SELECT 
    n.n_name,
    COALESCE(SUM(r.rank), 0) AS total_rank,
    COUNT(DISTINCT h.c_custkey) AS high_value_customers,
    MAX(s.supplier_count) AS most_suppliers_for_part,
    (SELECT COUNT(*) FROM lineitem l WHERE l.l_returnflag = 'R') AS returned_items
FROM 
    NationWithParts n
LEFT JOIN 
    RankedSuppliers r ON r.rank <= 5
LEFT JOIN 
    HighValueCustomers h ON h.total_spent > 20000
LEFT JOIN 
    SupplierPartCount s ON s.supplier_count = (SELECT MAX(supplier_count) FROM SupplierPartCount)
WHERE 
    n.part_count > 0
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT h.c_custkey) > 2 
    AND COALESCE(MAX(s.supplier_count), 0) < 10
ORDER BY 
    total_rank DESC, high_value_customers ASC
