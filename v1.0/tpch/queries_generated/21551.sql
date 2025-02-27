WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_size
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 20 AND 
        (p.p_retailprice IS NULL OR p.p_retailprice < 50.00)
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_custkey
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('F', 'P')
    AND 
        EXISTS (
            SELECT 1 FROM customer c WHERE c.c_custkey = o.o_custkey AND c.c_acctbal > 100
        )
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_revenue,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT p.p_name) as part_names,
    SUM(CASE 
            WHEN lp.l_returnflag = 'R' THEN lp.l_quantity 
            ELSE 0 
        END) AS returned_quantity
FROM 
    nation n
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = s.s_suppkey AND rs.rank <= 5
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    FilteredParts p ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem lp ON lp.l_partkey = p.p_partkey 
LEFT JOIN 
    CustomerOrders co ON co.o_orderkey = lp.l_orderkey
WHERE 
    (n.n_name IS NOT NULL AND n.n_name LIKE '%land%')
    OR 
    (s.s_name IS NULL AND co.o_totalprice >= ANY (SELECT MAX(o.o_totalprice) FROM orders o GROUP BY o.o_orderpriority))
GROUP BY 
    n.n_name
HAVING 
    SUM(CASE WHEN lp.l_tax > 0 THEN 1 ELSE 0 END) > 10
ORDER BY 
    total_revenue DESC
LIMIT 100 OFFSET 10;
