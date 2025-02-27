WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank
    FROM 
        customer c
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_customerkey,
        COUNT(l.l_linenumber) AS total_line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_customerkey
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)

SELECT 
    rc.c_name AS customer_name,
    rc.c_acctbal AS account_balance,
    os.total_line_items,
    os.total_value,
    COALESCE(ss.total_supply_cost, 0) AS supply_cost
FROM 
    RankedCustomers rc
LEFT JOIN 
    OrderStats os ON rc.c_custkey = os.o_customerkey
LEFT JOIN 
    SupplierStats ss ON os.total_line_items > 10 AND ss.ps_partkey IN (
        SELECT ps_partkey 
        FROM partsupp 
        WHERE ps_supplycost > 100
    )
WHERE 
    rc.rank = 1 AND 
    rc.c_acctbal IS NOT NULL
ORDER BY 
    rc.c_acctbal DESC;

WITH QuantityStats AS (
   SELECT 
       l.l_partkey, 
       SUM(l.l_quantity) AS total_quantity
   FROM 
       lineitem l
   GROUP BY 
       l.l_partkey
)

SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_brand, 
    q.total_quantity,
    p.p_retailprice * q.total_quantity AS total_retail_value
FROM
    part p
JOIN 
    QuantityStats q ON p.p_partkey = q.l_partkey
WHERE 
    p.p_retailprice * q.total_quantity > 5000
ORDER BY 
    total_retail_value DESC;
