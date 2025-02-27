WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT CASE
                                            WHEN r.r_name = 'ASIA' THEN 10
                                            ELSE 5
                                        END
                       FROM region r)
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(NULLIF(s.s_address, ''), 'Unknown') AS supplier_address,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_address
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c1.c_acctbal) FROM customer c1)
    GROUP BY c.c_custkey
),
QualifiedItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        p.p_name,
        l.l_quantity,
        l.l_discount,
        l.l_extendedprice * (1 - l.l_discount) AS net_price
    FROM lineitem l
    JOIN RankedParts p ON l.l_partkey = p.p_partkey
    WHERE p.price_rank <= 3
)
SELECT 
    co.total_orders,
    SUM(qi.net_price) AS total_revenue,
    COUNT(DISTINCT si.s_suppkey) AS unique_suppliers_used,
    STRING_AGG(DISTINCT p.p_name ORDER BY p.p_name) AS part_names
FROM CustomerOrders co
LEFT JOIN QualifiedItems qi ON co.total_orders > 0
LEFT JOIN SupplierInfo si ON qi.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < si.total_supply_cost)
GROUP BY co.total_orders
HAVING SUM(qi.net_price) IS NOT NULL OR COUNT(si.s_suppkey) = 0
ORDER BY total_revenue DESC;
