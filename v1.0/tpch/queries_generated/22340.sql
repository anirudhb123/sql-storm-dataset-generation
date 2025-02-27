WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_size,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_per_brand
    FROM
        part p
    WHERE
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 20)
),
OrderDetails AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_qty,
        COUNT(DISTINCT l.l_partkey) AS unique_parts_ordered
    FROM
        orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey
),
SupplierData AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM
        supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
)
SELECT
    r.r_name,
    COALESCE(od.o_orderkey, 0) AS order_key,
    pp.p_name,
    pp.p_retailprice,
    sd.s_name AS supplier_name,
    sd.parts_supplied,
    sd.total_supply_cost,
    COUNT(DISTINCT od.o_orderkey) OVER (PARTITION BY r.r_name) AS orders_per_region,
    CASE 
        WHEN pp.rank_per_brand <= 3 THEN 'Top Rank'
        ELSE 'Other'
    END AS part_ranking,
    (SELECT COUNT(*) FROM customer c WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal >= 100) AS wealthy_customers
FROM
    RankedParts pp
LEFT JOIN OrderDetails od ON pp.p_partkey = od.o_orderkey
LEFT JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT MIN(c.c_nationkey) FROM customer c))
LEFT JOIN SupplierData sd ON pp.p_partkey = sd.parts_supplied
WHERE
    pp.rank_per_brand IS NOT NULL OR pp.p_retailprice IS NULL
ORDER BY
    r.r_name, pp.p_retailprice DESC, sd.total_supply_cost ASC;
