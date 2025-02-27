WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size <= 20)
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(CASE WHEN ps.ps_availqty > 10 THEN ps.ps_supplycost ELSE NULL END) IS NOT NULL
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS total_lines,
        AVG(o.o_totalprice) AS avg_total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    si.s_name,
    si.total_supply_cost,
    os.avg_total_price,
    (SELECT COUNT(DISTINCT c.c_custkey) 
     FROM customer c 
     WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')) AS total_customers_us
FROM 
    RankedParts p
LEFT JOIN 
    SupplierInfo si ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0 LIMIT 1)
FULL OUTER JOIN 
    OrderSummary os ON os.total_lines > 0
WHERE 
    p.rn <= 5 
    AND (si.total_supply_cost IS NULL OR si.total_supply_cost > 1000)
ORDER BY 
    p.p_retailprice DESC, si.total_supply_cost ASC;
