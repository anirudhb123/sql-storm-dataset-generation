WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
), 
SupplierWithMaxCost AS (
    SELECT 
        ps.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.s_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (
            SELECT 
                AVG(ps1.ps_supplycost * ps1.ps_availqty)
            FROM 
                partsupp ps1
        )
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(o.o_orderkey) > (
            SELECT 
                AVG(order_count) 
            FROM (
                SELECT 
                    COUNT(o1.o_orderkey) AS order_count
                FROM 
                    customer c1
                LEFT JOIN orders o1 ON c1.c_custkey = o1.o_custkey
                GROUP BY 
                    c1.c_custkey
            ) AS subquery
        )
), 
ProductSuppliers AS (
    SELECT 
        l.l_partkey,
        s.s_name,
        COUNT(*) AS supplier_count
    FROM 
        lineitem l
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    GROUP BY 
        l.l_partkey, s.s_name
)

SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    swc.total_supply_cost,
    co.order_count,
    ps.supplier_count,
    CASE 
        WHEN rp.price_rank = 1 THEN 'Most Expensive'
        ELSE 'Regular Price'
    END AS price_category
FROM 
    RankedParts rp
LEFT JOIN SupplierWithMaxCost swc ON swc.s_suppkey = (
    SELECT 
        ps.s_suppkey 
    FROM 
        partsupp ps 
    WHERE 
        ps.ps_partkey = rp.p_partkey 
    ORDER BY 
        ps.ps_supplycost DESC 
    LIMIT 1
)
LEFT JOIN CustomerOrders co ON co.c_custkey = (
    SELECT 
        o.o_custkey 
    FROM 
        orders o 
    WHERE 
        o.o_orderkey = (
            SELECT 
                o2.o_orderkey 
            FROM 
                orders o2 
            WHERE 
                o2.o_totalprice > rp.p_retailprice * 0.9 
            ORDER BY 
                o2.o_orderdate DESC 
            LIMIT 1
        )
)
LEFT JOIN ProductSuppliers ps ON ps.l_partkey = rp.p_partkey
WHERE 
    rp.p_retailprice IS NOT NULL AND 
    (ps.supplier_count IS NOT NULL OR co.order_count IS NULL)
ORDER BY 
    rp.p_partkey DESC, swc.total_supply_cost ASC;
