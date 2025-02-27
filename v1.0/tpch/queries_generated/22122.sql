WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn,
        p.p_type
    FROM 
        part p
    WHERE 
        p.p_size IS NOT NULL
),
ExpensiveSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        total_supplycost > (
            SELECT AVG(total_supplycost)
            FROM (
                SELECT 
                    SUM(ps_supplycost) AS total_supplycost
                FROM 
                    partsupp ps
                GROUP BY 
                    ps.ps_suppkey
            ) avg_cost
        )
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(DISTINCT o.o_orderkey) AS order_count, 
        MIN(o.o_orderdate) AS first_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 5
),
FullOuterJoin AS (
    SELECT 
        r.r_name, 
        COALESCE(n.n_name, 'Unknown Nation') AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(p.p_retailprice) AS total_retail_price
    FROM 
        region r
    FULL OUTER JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        part p ON s.s_suppkey IN (
            SELECT ps.ps_suppkey
            FROM partsupp ps
            WHERE ps.ps_partkey IN (
                SELECT p_partkey
                FROM RankedParts
                WHERE rn <= 10
            )
        )
    GROUP BY 
        r.r_name, n.n_name
)

SELECT 
    foj.nation_name,
    COALESCE(foj.supplier_count, 0) AS supplier_count,
    COALESCE(foj.total_retail_price, 0) AS total_retail_price,
    cp.order_count,
    cp.first_order_date
FROM 
    FullOuterJoin foj
LEFT JOIN 
    CustomerOrders cp ON foj.nation_name = cp.c_custkey
WHERE 
    foj.total_retail_price IS NOT NULL
ORDER BY 
    foj.total_retail_price DESC, 
    cp.order_count DESC
LIMIT 20;
