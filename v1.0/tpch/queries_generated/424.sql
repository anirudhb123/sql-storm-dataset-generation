WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
SupplierAvailability AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    STRING_AGG(DISTINCT p.p_name, ', ') AS popular_parts,
    AVG(cs.total_spent) AS avg_customer_spend,
    SUM(sa.total_available) AS total_supplier_availability
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    CustomerOrderStats cs ON cs.c_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = n.n_nationkey AND c.c_acctbal IS NOT NULL
    )
LEFT JOIN 
    RankedSales p ON p.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_availqty > 0
    )
LEFT JOIN 
    SupplierAvailability sa ON sa.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = p.p_partkey 
        LIMIT 1
    )
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT n.n_nationkey) > 2
ORDER BY 
    avg_customer_spend DESC;
