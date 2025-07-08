WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01'
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(*) AS supplier_count
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
HighValueLines AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
)
SELECT 
    p.p_name,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    r.o_orderstatus,
    r.o_totalprice,
    hvl.total_price AS high_value_total
FROM part p
LEFT JOIN SupplierStats ss ON p.p_partkey = ss.ps_partkey
LEFT JOIN RankedOrders r ON r.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderkey = r.o_orderkey AND o.o_orderstatus = 'O' LIMIT 1)
LEFT JOIN HighValueLines hvl ON hvl.l_orderkey = r.o_orderkey
WHERE (ss.supplier_count > 5 OR ss.total_supply_cost IS NULL) 
AND r.o_orderstatus IS NOT NULL
ORDER BY total_supply_cost DESC, p.p_name;