WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) as rnk
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 50
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 1000
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
    AND o.o_orderdate >= '2022-01-01'
),
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax
    FROM lineitem l
    JOIN HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey
),
PartsWithSupplierInfo AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        COALESCE(SUM(CASE WHEN fs.total_supplycost IS NOT NULL THEN fs.total_supplycost ELSE 0 END), 0) AS supplier_cost
    FROM RankedParts rp
    LEFT JOIN FilteredSuppliers fs ON rp.p_partkey = fs.s_suppkey
    WHERE rp.rnk <= 3
    GROUP BY rp.p_partkey, rp.p_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    od.l_quantity,
    od.l_extendedprice * (1 - od.l_discount) AS net_price,
    SUM(od.l_tax) OVER (PARTITION BY od.l_orderkey) AS total_tax,
    CASE 
        WHEN od.l_quantity > 100 THEN 'High Volume'
        ELSE 'Standard Volume'
    END AS volume_category,
    CASE 
        WHEN p.p_retailprice IS NULL THEN 'Price Not Found'
        ELSE 'Price Exists'
    END AS price_status
FROM PartsWithSupplierInfo p
JOIN OrderDetails od ON p.p_partkey = od.l_partkey
WHERE p.supplier_cost > (SELECT AVG(supplier_cost) FROM PartsWithSupplierInfo)
ORDER BY total_tax DESC NULLS LAST;
