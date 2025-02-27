
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        SUM(l.l_quantity) AS total_sold,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_sold_price
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_type
)
SELECT 
    so.o_orderkey,
    so.o_orderdate,
    ps.total_cost AS supplier_total_cost,
    ps.total_parts AS supplier_part_count,
    pd.total_sold AS part_total_sold,
    pd.avg_sold_price AS part_avg_price
FROM RankedOrders so
JOIN SupplierStats ps ON ps.s_suppkey = (
    SELECT ps_partkey FROM partsupp ORDER BY ps_supplycost DESC LIMIT 1
)
JOIN PartDetails pd ON pd.p_partkey = (
    SELECT l_partkey FROM lineitem WHERE l_orderkey = so.o_orderkey ORDER BY l_extendedprice DESC LIMIT 1
)
WHERE so.order_rank = 1
ORDER BY so.o_orderdate DESC, supplier_total_cost DESC;
