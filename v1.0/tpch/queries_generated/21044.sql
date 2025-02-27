WITH SelectedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
),

HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL AND 
        LENGTH(s.s_name) > 5
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        AVG(s.s_acctbal) > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_acctbal IS NOT NULL)
),

AggregateOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_linenumber) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus <> 'F' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
),

FormattedResults AS (
    SELECT 
        o.o_orderkey,
        COALESCE(NULLIF(c.c_name, ''), 'Unknown Customer') AS customer_name,
        (CASE 
            WHEN o.o_orderdate < CURRENT_DATE - INTERVAL '1 YEAR' THEN 'Old'
            ELSE 'Recent'
         END) AS order_age,
        total_price,
        item_count
    FROM 
        AggregateOrders o
    JOIN 
        customer c ON o.o_orderkey % (c.c_custkey + 1) = 0
)

SELECT 
    f.o_orderkey,
    f.customer_name,
    f.order_age,
    f.total_price,
    COALESCE(SP.p_name, 'No Valid Part') AS part_name,
    COALESCE(SP.p_retailprice, 0) AS part_price,
    HS.avg_acctbal
FROM 
    FormattedResults f
LEFT JOIN 
    SelectedParts SP ON f.o_orderkey = SP.rn
LEFT JOIN 
    HighValueSuppliers HS ON HS.s_suppkey = f.o_orderkey MOD 10
WHERE 
    f.total_price > (SELECT AVG(total_price) FROM FormattedResults)
ORDER BY 
    f.total_price DESC, 
    f.customer_name ASC;
