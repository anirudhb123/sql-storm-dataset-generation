WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
        AND s.s_acctbal > 5000
),
AggregatedData AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_revenue,
        STRING_AGG(DISTINCT s.s_name, ', ') AS top_suppliers
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        RankedSuppliers rs ON rs.s_suppkey IN (
            SELECT ps.ps_suppkey 
            FROM partsupp ps 
            JOIN part p ON ps.ps_partkey = p.p_partkey 
            WHERE p.p_brand = (SELECT p_brand FROM part WHERE p_partkey = rs.s_suppkey)
        )
    GROUP BY 
        n.n_name
)
SELECT 
    nation_name,
    customer_count,
    total_revenue,
    top_suppliers
FROM 
    AggregatedData
WHERE 
    customer_count > 10
ORDER BY 
    total_revenue DESC;
