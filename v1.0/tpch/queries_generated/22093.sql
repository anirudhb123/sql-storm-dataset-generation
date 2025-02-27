WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        DENSE_RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank_price,
        SUM(ps.ps_supplycost * ps.ps_availqty) OVER (PARTITION BY p.p_partkey) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        lineitem l ON l.l_suppkey = s.s_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(total_revenue) FROM (
            SELECT SUM(l_extendedprice * (1 - l_discount)) AS total_revenue 
            FROM lineitem 
            GROUP BY l_suppkey
        ) AS avg_subquery)
), 
ActiveOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
    HAVING 
        COUNT(l.l_orderkey) > 0
)
SELECT 
    rp.p_name, 
    rp.p_retailprice, 
    ts.s_name AS supplier_name, 
    ao.o_orderkey, 
    ao.o_orderstatus,
    rp.total_supply_cost,
    CASE 
        WHEN rp.rank_price = 1 THEN 'Top Price'
        WHEN rp.rank_price <= 5 THEN 'High Price'
        ELSE 'Standard Price'
    END AS price_category
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON rp.p_partkey = (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey = ts.s_suppkey 
        ORDER BY ps.ps_supplycost ASC 
        LIMIT 1
    )
FULL OUTER JOIN 
    ActiveOrders ao ON ao.o_orderkey = (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderkey IS NOT NULL 
        ORDER BY o.o_orderdate DESC 
        LIMIT 1
    )
WHERE 
    rp.total_supply_cost IS NOT NULL OR ao.o_orderstatus = 'F'
ORDER BY 
    rp.p_retailprice DESC, 
    ts.total_revenue DESC 
LIMIT 100;
