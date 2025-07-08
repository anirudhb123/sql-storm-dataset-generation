
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER(PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_within_nation
    FROM supplier s
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        l.l_partkey,
        l.l_quantity,
        l.l_discount,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice * (1 - l.l_discount) AS discounted_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN part p ON l.l_partkey = p.p_partkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipmode IN ('AIR', 'SHIP')
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
FinalResult AS (
    SELECT 
        od.o_orderkey,
        od.o_orderdate,
        od.l_partkey,
        od.discounted_price,
        COALESCE(sa.total_availqty, 0) AS total_availqty,
        RANK() OVER(ORDER BY od.discounted_price DESC) AS price_rank
    FROM OrderDetails od
    LEFT JOIN SupplierAvailability sa ON od.l_partkey = sa.ps_partkey
)

SELECT 
    fr.o_orderkey,
    fr.o_orderdate,
    fr.l_partkey,
    fr.discounted_price,
    fr.total_availqty,
    CASE 
        WHEN fr.total_availqty = 0 THEN 'No Availability'
        WHEN fr.total_availqty < 50 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status,
    CASE 
        WHEN GROUPING(fr.o_orderkey) > 0 THEN 'Grand Total'
        ELSE 'Details'
    END AS summary_type
FROM FinalResult fr
GROUP BY 
    fr.o_orderkey,
    fr.o_orderdate,
    fr.l_partkey,
    fr.discounted_price,
    fr.total_availqty
HAVING 
    SUM(fr.discounted_price) > 1000
ORDER BY 
    fr.discounted_price DESC, fr.o_orderdate ASC, fr.l_partkey DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY
