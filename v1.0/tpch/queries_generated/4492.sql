WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
),
PartSupplierSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_available,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.total_available,
    hs.s_name AS top_supplier,
    c.c_name AS high_value_customer,
    hvc.total_spent
FROM 
    PartSupplierSummary p
LEFT JOIN 
    RankedSuppliers r ON r.rank = 1 AND r.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
LEFT JOIN 
    HighValueCustomers hvc ON hvc.total_spent > 1500
LEFT JOIN 
    nation n ON n.n_nationkey IN (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = hvc.c_custkey)
LEFT JOIN 
    supplier hs ON hs.s_suppkey = r.s_suppkey
WHERE 
    p.total_available < (SELECT AVG(ps.ps_availqty) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
ORDER BY 
    p.p_partkey;
