WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
),
SupplierSupplierCount AS (
    SELECT 
        ps.ps_suppkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    GROUP BY ps.ps_suppkey
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COALESCE(ps.ps_availqty, 0) AS available_quantity,
        MAX(ps.ps_supplycost) AS max_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
OrderLineSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price,
        COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(p.p_name, 'Unknown Part') AS part_name,
    p.available_quantity,
    s.supplier_count,
    ol.total_line_price,
    ROW_NUMBER() OVER (PARTITION BY r.o_orderstatus ORDER BY r.o_totalprice DESC) AS order_position
FROM RankedOrders r
LEFT JOIN PartSupplierDetails p ON r.o_orderkey = (SELECT MIN(l.l_orderkey) FROM lineitem l WHERE l.l_orderkey = r.o_orderkey)
LEFT JOIN SupplierSupplierCount s ON s.ps_suppkey = r.o_orderkey
LEFT JOIN OrderLineSummary ol ON ol.l_orderkey = r.o_orderkey
WHERE r.order_rank <= 3
  AND (p.max_supply_cost > 500 OR p.max_supply_cost IS NULL)
ORDER BY r.o_orderdate DESC, order_position;
