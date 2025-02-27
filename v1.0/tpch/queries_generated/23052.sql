WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 25
), 
SupplierMax AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_availqty) AS total_avail,
        MAX(s.s_acctbal) AS max_acctbal
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), 
OrderStatistics AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) OVER (PARTITION BY o.o_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY o.o_orderkey) AS total_price
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
), 
SupplierPartDetails AS (
    SELECT 
        sp.ps_partkey, 
        sr.r_name AS region, 
        sp.total_avail, 
        rp.price_rank
    FROM SupplierMax sp
    JOIN nation n ON sp.ps_suppkey = n.n_nationkey
    JOIN region sr ON n.n_regionkey = sr.r_regionkey
    JOIN RankedParts rp ON sp.ps_partkey = rp.p_partkey
), 
FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        os.lineitem_count
    FROM orders o
    JOIN OrderStatistics os ON o.o_orderkey = os.o_orderkey
    WHERE o.o_totalprice > 1000 AND os.lineitem_count > 5
)
SELECT 
    fld.o_orderkey,
    fld.o_totalprice,
    COUNT(sp.partkey) AS total_parts,
    SUM(sp.total_avail) AS total_avail_parts,
    STRING_AGG(sp.region, ', ') AS region_list
FROM FilteredOrders fld
LEFT JOIN SupplierPartDetails sp ON fld.o_orderkey = (SELECT 
        o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderkey = fld.o_orderkey)
GROUP BY fld.o_orderkey, fld.o_totalprice
HAVING SUM(sp.total_avail) > (SELECT 
        AVG(total_price) 
        FROM OrderStatistics)
ORDER BY fld.o_totalprice DESC
LIMIT 10;
