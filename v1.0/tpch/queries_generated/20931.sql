WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
AvailableParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_available
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        COALESCE(SUM(ps.ps_availqty), 0) > 0
),
TopOrders AS (
    SELECT 
        ho.o_orderkey,
        ho.total_value,
        ROW_NUMBER() OVER (ORDER BY ho.total_value DESC) AS order_rank
    FROM 
        HighValueOrders ho
    WHERE 
        ho.total_value IS NOT NULL
)
SELECT 
    p.p_name,
    p.total_available,
    su.s_name AS supplier_name,
    o.order_rank
FROM 
    AvailableParts p
LEFT JOIN 
    RankedSuppliers su ON su.rank_within_nation = 1
LEFT JOIN 
    TopOrders o ON o.o_orderkey = (
        SELECT 
            ho.o_orderkey 
        FROM 
            HighValueOrders ho 
        WHERE 
            ho.total_value = (
                SELECT 
                    MAX(ho2.total_value) 
                FROM 
                    HighValueOrders ho2 
                WHERE 
                    ho2.total_value < o.total_value
            )
        LIMIT 1
    )
WHERE 
    p.total_available > 0
AND 
    su.s_name IS NOT NULL
ORDER BY 
    p.p_name, o.order_rank DESC NULLS LAST;
