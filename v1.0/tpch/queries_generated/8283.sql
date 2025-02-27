WITH SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 

RegionNation AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        n.n_nationkey,
        n.n_name
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
), 

CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    r.r_name as region,
    n.n_name as nation,
    COUNT(DISTINCT spi.s_suppkey) AS supplier_count,
    SUM(spi.total_cost) AS total_supplier_cost,
    COUNT(DISTINCT cos.c_custkey) AS customer_count,
    SUM(cos.total_spent) AS total_customer_spent
FROM 
    RegionNation r
JOIN 
    SupplierPartInfo spi ON r.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
JOIN 
    CustomerOrderStats cos ON cos.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE 'A%')
GROUP BY 
    r.r_regionkey, r.r_name, n.n_name
ORDER BY 
    total_supplier_cost DESC;
