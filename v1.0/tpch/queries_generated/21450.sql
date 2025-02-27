WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COALESCE(MAX(ps.ps_supplycost), 0) AS max_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        AVG(o.o_totalprice) AS avg_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
NationRegion AS (
    SELECT 
        n.n_name,
        ROW_NUMBER() OVER (ORDER BY r.r_name) AS region_rank,
        COUNT(n.n_nationkey) AS nation_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_name
)
SELECT 
    r.n_name AS nation_name,
    rsp.parts_supplied,
    COALESCE(cos.avg_order_value, 0) AS avg_order_value,
    CASE 
        WHEN rsp.total_cost IS NULL THEN 'No Supplies'
        ELSE 'Supplied'
    END AS supply_status,
    SUM(ros.total_revenue) AS total_order_revenue
FROM NationRegion r
LEFT JOIN SupplierStats rsp ON r.region_rank = rsp.parts_supplied
LEFT JOIN CustomerOrderStats cos ON r.nation_count = cos.order_count
LEFT JOIN RankedOrders ros ON r.n_name = (SELECT n2.n_name FROM nation n2 WHERE n2.n_nationkey = r.region_rank)
GROUP BY r.n_name, rsp.parts_supplied
HAVING SUM(ros.total_revenue) > (SELECT AVG(total_revenue) FROM RankedOrders WHERE revenue_rank < 3)
ORDER BY r.n_name DESC
LIMIT 10;
