WITH SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_partkey, 
        p.p_name, 
        ps.ps_availqty, 
        ps.ps_supplycost 
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey 
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s_acctbal) FROM supplier WHERE n_nationkey IN (
                SELECT n_nationkey FROM nation WHERE n_regionkey IN (1, 2)
            )
        )
),
FrequentCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count 
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey, c.c_name 
    HAVING 
        COUNT(o.o_orderkey) > 5
),
SalesSummary AS (
    SELECT 
        fp.s_suppkey, 
        fp.s_name, 
        fc.c_custkey, 
        fc.c_name, 
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales 
    FROM 
        SupplierParts fp 
    JOIN 
        lineitem li ON fp.p_partkey = li.l_partkey 
    JOIN 
        orders o ON li.l_orderkey = o.o_orderkey 
    JOIN 
        FrequentCustomers fc ON o.o_custkey = fc.c_custkey 
    WHERE 
        li.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31' 
    GROUP BY 
        fp.s_suppkey, fp.s_name, fc.c_custkey, fc.c_name 
)
SELECT 
    ss.s_suppkey, 
    ss.s_name, 
    COUNT(DISTINCT ss.c_custkey) AS unique_customers, 
    SUM(ss.total_sales) AS total_revenue 
FROM 
    SalesSummary ss 
GROUP BY 
    ss.s_suppkey, ss.s_name 
ORDER BY 
    total_revenue DESC 
LIMIT 10;
