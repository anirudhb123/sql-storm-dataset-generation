WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name, s.s_nationkey
),
HighValueSuppliers AS (
    SELECT 
        s.r_name,
        s.n_name,
        r.total_supply_value
    FROM RankedSuppliers r
    JOIN nation n ON r.s_nationkey = n.n_nationkey
    JOIN region s ON n.n_regionkey = s.r_regionkey
    WHERE r.rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name
)
SELECT 
    hvs.r_name AS region,
    hvs.n_name AS nation,
    hvs.total_supply_value,
    co.c_name AS customer,
    co.total_order_value
FROM HighValueSuppliers hvs
JOIN CustomerOrders co ON hvs.total_supply_value > co.total_order_value
ORDER BY hvs.region, hvs.nation, co.total_order_value DESC;
