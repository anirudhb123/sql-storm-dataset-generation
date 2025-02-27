WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
), 
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), 
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
)

SELECT 
    cd.c_custkey,
    c.first_purchase,
    p.p_name,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    ROUND(cd.total_spent, 2) AS total_spent,
    pd.p_retailprice * 1.1 AS adjusted_price,
    ROW_NUMBER() OVER (PARTITION BY cd.c_custkey ORDER BY pd.p_retailprice DESC) AS rank
FROM 
    CustomerOrderStats cd
JOIN 
    PartDetails pd ON pd.supplier_count > 5
LEFT JOIN 
    RankedSuppliers s ON s.s_suppkey = (SELECT ps.ps_suppkey 
                                         FROM partsupp ps 
                                         WHERE ps.ps_partkey = pd.p_partkey 
                                         ORDER BY ps.ps_supplycost LIMIT 1)
LEFT JOIN 
    (SELECT DISTINCT 
         o.o_custkey,
         MIN(o.o_orderdate) AS first_purchase 
     FROM 
         orders o 
     GROUP BY 
         o.o_custkey) c ON c.o_custkey = cd.c_custkey
WHERE 
    cd.order_count > 10
    AND pd.p_retailprice BETWEEN 50 AND 150
ORDER BY 
    cd.total_spent DESC, adjusted_price;
