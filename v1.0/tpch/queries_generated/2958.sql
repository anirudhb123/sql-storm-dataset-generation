WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
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
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
PartSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2023-12-31'
    GROUP BY 
        p.p_partkey
)
SELECT 
    p.p_name,
    COALESCE(hvc.c_name, 'Unknown') AS top_customer,
    COALESCE(sup.s_name, 'No Supplier') AS top_supplier,
    ps.total_sales,
    RANK() OVER (ORDER BY ps.total_sales DESC) AS sales_rank
FROM 
    PartSales ps
LEFT JOIN 
    RankedSuppliers sup ON ps.p_partkey = sup.ps_partkey AND sup.rank = 1
LEFT JOIN 
    HighValueCustomers hvc ON EXISTS (
        SELECT 1 
        FROM orders o 
        WHERE o.o_custkey = hvc.c_custkey 
        AND o.o_orderkey IN (
            SELECT l.l_orderkey 
            FROM lineitem l 
            WHERE l.l_partkey = ps.p_partkey
        )
    )
JOIN 
    part p ON ps.p_partkey = p.p_partkey
WHERE 
    p.p_retailprice IS NOT NULL
ORDER BY 
    sales_rank
LIMIT 100;
