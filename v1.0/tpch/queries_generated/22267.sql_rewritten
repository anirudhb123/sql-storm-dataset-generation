WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 20
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS recent_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F') 
      AND o.o_totalprice > (
          SELECT AVG(o2.o_totalprice) 
          FROM orders o2 
          WHERE o2.o_orderdate < cast('1998-10-01' as date)
      )
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        s.s_name, 
        ps.ps_supplycost,
        COALESCE(lp.l_quantity, 0) AS sold_quantity,
        CASE WHEN COALESCE(lp.l_discount, 0) > 0 THEN 'Discounted' ELSE 'Regular' END AS price_type
    FROM RankedParts p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN lineitem lp ON lp.l_partkey = p.p_partkey
)
SELECT 
    ns.n_name AS nation,
    SUM(sd.ps_supplycost * sd.sold_quantity) AS total_cost,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT sd.price_type, ', ') AS price_types
FROM nation ns
LEFT JOIN SupplierInfo si ON si.s_suppkey = ns.n_nationkey
LEFT JOIN PartSupplierDetails sd ON sd.s_name = si.s_name
LEFT JOIN RecentOrders ro ON ro.o_orderkey = sd.p_partkey
WHERE sd.sold_quantity IS NOT NULL
GROUP BY ns.n_name
HAVING SUM(sd.ps_supplycost * sd.sold_quantity) > (
    SELECT AVG(total_cost) 
    FROM (
        SELECT SUM(ps_supplycost * sold_quantity) AS total_cost
        FROM PartSupplierDetails
        GROUP BY p_partkey
    ) AS subquery
) OR COUNT(DISTINCT ro.o_orderkey) > 10
ORDER BY total_cost DESC NULLS LAST;