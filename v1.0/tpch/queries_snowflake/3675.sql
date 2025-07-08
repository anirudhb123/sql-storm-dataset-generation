WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
), 
FrequentCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' OR o.o_orderkey IS NULL
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
    HAVING 
        COUNT(o.o_orderkey) > 5
), 
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty * p.p_retailprice) AS total_value,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    COALESCE(f.c_name, 'No Orders') AS customer_name,
    r.s_name AS supplier_name,
    psd.total_value,
    psd.supplier_count,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY psd.total_value DESC) AS value_rank
FROM 
    part p
LEFT JOIN 
    PartSupplierDetails psd ON p.p_partkey = psd.ps_partkey
LEFT JOIN 
    RankedSuppliers r ON r.rnk = 1 AND psd.supplier_count > 0
LEFT JOIN 
    FrequentCustomers f ON f.c_nationkey = (
        SELECT n.n_regionkey
        FROM nation n
        WHERE n.n_nationkey = r.s_suppkey
    )
WHERE 
    p.p_retailprice > 100.00
ORDER BY 
    p.p_partkey, value_rank;
