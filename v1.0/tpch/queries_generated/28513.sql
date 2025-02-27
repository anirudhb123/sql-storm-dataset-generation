WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
PopularParts AS (
    SELECT 
        ps.ps_partkey, 
        COUNT(*) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        COUNT(*) > 5
),
CustomerSpending AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spending
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartDetails AS (
    SELECT 
        p.p_name, 
        p.p_brand, 
        p.p_size, 
        r.r_name AS region_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey 
    WHERE 
        p.p_retailprice > 50.00
)
SELECT 
    cp.c_name, 
    cp.total_spending, 
    pp.p_name, 
    pp.p_brand, 
    pp.p_size, 
    COUNT(DISTINCT rs.s_suppkey) AS supplier_rank
FROM 
    CustomerSpending cp
JOIN 
    PartDetails pp ON cp.c_custkey IN (SELECT o.o_custkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_partkey IN (SELECT ps.ps_partkey FROM PopularParts ps))
JOIN 
    RankedSuppliers rs ON pp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rs.s_suppkey AND rs.rn <= 3)
GROUP BY 
    cp.c_name, 
    cp.total_spending, 
    pp.p_name, 
    pp.p_brand, 
    pp.p_size
ORDER BY 
    cp.total_spending DESC, 
    pp.p_name;
