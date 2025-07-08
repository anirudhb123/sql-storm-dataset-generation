
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM supplier s
),
PartCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_custkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS recent_order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(month, -6, CURRENT_DATE)
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        r.r_name AS region_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey, r.r_name
)
SELECT 
    cd.c_name,
    cd.order_count,
    rs.s_name AS top_supplier,
    pc.total_cost,
    CASE 
        WHEN cd.order_count > 0 AND pc.total_cost IS NOT NULL THEN pc.total_cost / NULLIF(cd.order_count, 0)
        ELSE 0
    END AS avg_cost_per_order
FROM CustomerDetails cd
LEFT JOIN RecentOrders ro ON cd.c_custkey = ro.o_custkey AND ro.recent_order_rank = 1
LEFT JOIN RankedSuppliers rs ON rs.rank_acctbal = 1
LEFT JOIN PartCosts pc ON pc.ps_partkey IN (
    SELECT l.l_partkey
    FROM lineitem l
    WHERE l.l_orderkey = ro.o_orderkey AND l.l_returnflag = 'N'
    GROUP BY l.l_partkey
)
WHERE cd.order_count > 5
ORDER BY avg_cost_per_order DESC, cd.c_name ASC;
