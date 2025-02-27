WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate >= DATEADD(month, -6, CURRENT_DATE))
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    COALESCE(s_ranked.s_name, 'Unknown Supplier') AS supplier_name,
    hvo.o_orderkey, 
    hvo.o_totalprice, 
    hvo.lineitem_count
FROM 
    part p
LEFT JOIN 
    RankedSuppliers s_ranked ON p.p_type = (
        SELECT 
            p2.p_type 
        FROM 
            part p2 
        WHERE 
            p2.p_partkey = p.p_partkey
    )
LEFT JOIN 
    HighValueOrders hvo ON hvo.o_orderkey IN (
        SELECT 
            l.l_orderkey 
        FROM 
            lineitem l 
        WHERE 
            l.l_partkey = p.p_partkey
    )
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00)
ORDER BY 
    p.p_partkey, hvo.o_orderkey;
