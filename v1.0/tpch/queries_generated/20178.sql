WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) as rn
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00)
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_net_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > (
            SELECT AVG(total_net_price * 1.1) FROM (
                SELECT 
                    SUM(l_extendedprice * (1 - l_discount)) AS total_net_price
                FROM 
                    lineitem
                GROUP BY 
                    l_orderkey
            ) AS inner_avg
        )
)
SELECT 
    n.n_name,
    rp.p_name,
    COALESCE(SUM(f.total_net_price), 0) AS total_order_price,
    COALESCE(ss.total_supply_cost, 0) AS supplier_cost,
    CASE 
        WHEN COALESCE(SUM(f.total_net_price), 0) > 0 THEN (COALESCE(SUM(f.total_net_price), 0) - COALESCE(ss.total_supply_cost, 0))
        ELSE NULL 
    END AS profit_margin
FROM 
    nation n
LEFT JOIN 
    RankedParts rp ON n.n_nationkey = (SELECT s_nationkey FROM supplier s ORDER BY RAND() LIMIT 1)
LEFT JOIN 
    FilteredOrders f ON f.o_orderkey = (SELECT o_orderkey FROM orders ORDER BY RAND() LIMIT 1)
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey = (SELECT ps_suppkey FROM partsupp ORDER BY RAND() LIMIT 1)
WHERE 
    n.n_regionkey IS NULL OR n.n_comment LIKE '%important%'
GROUP BY 
    n.n_name, rp.p_name
HAVING 
    profit_margin IS NOT NULL OR profit_margin > 0
ORDER BY 
    profit_margin DESC NULLS LAST;
