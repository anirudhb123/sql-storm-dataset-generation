WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_orderstatus
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01' 
      AND o.o_orderdate < DATE '2023-01-01'
      AND o.o_totalprice IS NOT NULL
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity END), 0) AS returned_quantity,
        SUM(l.l_quantity) AS total_quantity_sold
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
),
FinalReport AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(od.total_price) AS total_ordered_value,
        COUNT(DISTINCT supp.s_suppkey) AS distinct_suppliers,
        AVG(ps.total_supply_value) AS avg_supply_value
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN RankedOrders ro ON c.c_custkey = ro.o_custkey
    JOIN SupplierStats ps ON EXISTS (
        SELECT 1 FROM partsupp ps2 
        WHERE ps2.ps_partkey IN (
            SELECT p.p_partkey 
            FROM PartDetails p 
            WHERE p.total_quantity_sold > 0
        ) AND ps2.ps_suppkey = ps.s_suppkey
    )
    JOIN (
        SELECT 
            l.l_orderkey, 
            SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
        FROM lineitem l
        WHERE l.l_shipdate IS NOT NULL
        GROUP BY l.l_orderkey
    ) od ON ro.o_orderkey = od.l_orderkey
    GROUP BY r.r_name
)
SELECT 
    region_name,
    customer_count,
    total_ordered_value,
    distinct_suppliers,
    avg_supply_value
FROM FinalReport
WHERE customer_count > (SELECT AVG(customer_count) FROM FinalReport)
ORDER BY total_ordered_value DESC
LIMIT 10;
