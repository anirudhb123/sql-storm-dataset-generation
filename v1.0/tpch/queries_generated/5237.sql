WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        r.r_name AS region_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE c.c_acctbal > 10000
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING total_cost > 500000
),
OrderLineAggregation AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    cd.c_name,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(ola.revenue) AS total_revenue,
    SUM(ts.total_cost) AS total_supplier_cost
FROM CustomerDetails cd
JOIN RankedOrders ro ON cd.c_custkey = ro.o_custkey
JOIN OrderLineAggregation ola ON ro.o_orderkey = ola.l_orderkey
JOIN TopSuppliers ts ON ts.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_orderkey = ro.o_orderkey
    LIMIT 1
)
WHERE ro.order_rank <= 5
GROUP BY cd.c_name
ORDER BY total_revenue DESC
LIMIT 10;
