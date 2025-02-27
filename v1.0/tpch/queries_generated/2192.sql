WITH Ranked Suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
SupplierStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(s.s_suppkey) AS total_suppliers,
        AVG(s.s_acctbal) AS average_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
OrderAnalysis AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        COUNT(DISTINCT li.l_partkey) AS number_of_parts
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        li.l_shipdate >= '2023-01-01' AND li.l_shipdate < CURRENT_DATE
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_regionkey,
    r.r_name,
    COALESCE(ss.total_suppliers, 0) AS supplier_count,
    COALESCE(ss.average_acctbal, 0.00) AS avg_supplier_acctbal,
    SUM(oa.total_sales) AS total_sales
FROM 
    region r
LEFT JOIN 
    SupplierStats ss ON r.r_regionkey = ss.n_nationkey
LEFT JOIN 
    OrderAnalysis oa ON oa.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        JOIN customer c ON o.o_custkey = c.c_custkey 
        WHERE c.c_nationkey = ss.n_nationkey
    )
GROUP BY 
    r.r_regionkey, r.r_name
HAVING 
    SUM(oa.total_sales) > 10000
ORDER BY 
    total_sales DESC
LIMIT 10;
