WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate) AS rn,
        COALESCE((SELECT COUNT(*)
                  FROM orders o2
                  WHERE o2.o_orderdate < o.o_orderdate AND o2.o_orderstatus = o.o_orderstatus), 0) AS previous_order_count
    FROM 
        orders o
), 
SupplierWithStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
PartAvgPrices AS (
    SELECT 
        p.p_partkey,
        AVG(p.p_retailprice) AS avg_price,
        CASE 
            WHEN COUNT(*) > 0 THEN 'Available' 
            ELSE 'Not Available' 
        END AS availability
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    ps.total_supply_cost,
    p.avg_price,
    p.availability,
    CASE 
        WHEN o.o_totalprice > 1000 THEN 'High Value'
        ELSE 'Regular Value'
    END AS order_value_category,
    CASE 
        WHEN EXISTS (SELECT 1 
                     FROM lineitem l 
                     WHERE l.l_orderkey = o.o_orderkey AND l.l_discount > 0) THEN 'Discounted'
        ELSE 'No Discount'
    END AS discount_status,
    ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank,
    UNIQUE_PARTS_COUNT
FROM 
    RankedOrders o
JOIN 
    SupplierWithStats ps ON ps.s_suppkey = (SELECT TOP 1 ps_suppkey 
                                              FROM partsupp 
                                              WHERE ps_partkey IN 
                                                  (SELECT p_partkey 
                                                   FROM part 
                                                   WHERE p_retailprice > 50) 
                                              ORDER BY ps_availqty DESC)
JOIN 
    PartAvgPrices p ON p.p_partkey = (SELECT p_partkey 
                                        FROM lineitem l 
                                        WHERE l.l_orderkey = o.o_orderkey 
                                        ORDER BY l_extendedprice DESC 
                                        LIMIT 1)
WHERE 
    o.o_orderdate >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY 
    o.o_orderdate ASC;
