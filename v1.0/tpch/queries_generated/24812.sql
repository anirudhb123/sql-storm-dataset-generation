WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        p.p_size, 
        ROW_NUMBER() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL 
        AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) 
                                FROM part p2 
                                WHERE p2.p_size = p.p_size)
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost) AS total_supply_cost, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name 
    HAVING 
        SUM(o.o_totalprice) > 2000
)
SELECT 
    r.n_name AS nation_name, 
    COUNT(DISTINCT hl.c_custkey) AS high_value_customer_count, 
    AVG(sp.total_supply_cost * hp.p_retained_price) AS avg_order_value
FROM 
    nation r 
LEFT JOIN 
    supplier s ON s.s_nationkey = r.n_nationkey
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    RankedParts hp ON hp.p_partkey = ps.ps_partkey 
LEFT JOIN 
    SupplierInfo sp ON sp.s_suppkey = s.s_suppkey 
LEFT JOIN 
    HighValueCustomers hl ON hl.c_custkey = (SELECT o.o_custkey 
                                               FROM orders o 
                                               WHERE o.o_orderkey = (SELECT MAX(o2.o_orderkey) 
                                                                      FROM orders o2 
                                                                      WHERE o2.o_custkey = hl.c_custkey))
GROUP BY 
    r.n_name 
HAVING 
    COUNT(DISTINCT hl.c_custkey) > 0 
    AND AVG(sp.total_supply_cost * hp.p_retailprice) > 5000
ORDER BY 
    nation_name ASC;
