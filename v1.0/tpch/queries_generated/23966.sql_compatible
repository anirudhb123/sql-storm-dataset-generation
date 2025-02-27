
WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_nationkey, n.n_name
), HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('F', 'O')
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
), TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 50000 
), NationHighSales AS (
    SELECT 
        r.r_name,
        SUM(rs.total_sales) AS regional_sales
    FROM 
        region r
    LEFT JOIN 
        RegionalSales rs ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = rs.nation_name)
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    n.n_name,
    COALESCE(SUM(THC.total_spent), 0) AS high_value_customers_spent,
    COALESCE(SUM(NHS.regional_sales), 0) AS regional_sales
FROM 
    nation n
LEFT JOIN 
    HighValueCustomers THC ON n.n_nationkey = THC.c_custkey
LEFT JOIN 
    NationHighSales NHS ON n.n_nationkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = n.n_name)
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT THC.c_custkey) > 0 OR SUM(NHS.regional_sales) IS NOT NULL
ORDER BY 
    high_value_customers_spent DESC, regional_sales DESC;
