WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
PartSupplierCounts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.supplier_count,
        CASE 
            WHEN p.p_retailprice > 1000 THEN 'Expensive'
            WHEN p.p_retailprice BETWEEN 500 AND 1000 THEN 'Moderate'
            ELSE 'Cheap' 
        END AS price_category
    FROM 
        part p
    LEFT JOIN 
        PartSupplierCounts ps ON p.p_partkey = ps.ps_partkey
),
JoinSummary AS (
    SELECT 
        n.n_name AS nation_name,
        hs.s_name AS supplier_name,
        hp.p_name AS part_name,
        hp.price_category,
        hp.p_retailprice,
        cu.total_spent,
        cu.order_count
    FROM 
        HighValueParts hp
    LEFT JOIN 
        partsupp ps ON hp.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier hs ON ps.ps_suppkey = hs.s_suppkey
    LEFT JOIN 
        nation n ON hs.s_nationkey = n.n_nationkey
    LEFT JOIN 
        CustomerOrderSummary cu ON hs.s_suppkey = cu.c_custkey
)
SELECT 
    j.nation_name,
    j.supplier_name,
    j.part_name,
    j.price_category,
    j.p_retailprice,
    COALESCE(j.total_spent, 0) AS total_spent,
    COALESCE(j.order_count, 0) AS order_count,
    COUNT(DISTINCT j.supplier_name) OVER (PARTITION BY j.nation_name) AS total_suppliers_in_nation
FROM 
    JoinSummary j
WHERE 
    j.p_retailprice IS NOT NULL
ORDER BY 
    j.nation_name, j.price_category, j.total_spent DESC;
