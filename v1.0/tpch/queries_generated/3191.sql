WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
), SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_linenumber) AS item_count,
        MAX(l.l_shipdate) AS last_ship_date
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
)
SELECT 
    coalesce(c.c_name, 'Unknown Customer') AS customer_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT lo.o_orderkey) AS total_orders,
    SUM(l.total_price) AS total_lineitem_price,
    AVG(si.total_supply_cost) AS avg_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY coalesce(n.n_name, 'Unknown Nation') ORDER BY SUM(l.total_price) DESC) AS supply_rank
FROM customer c
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN RankedOrders ro ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey AND o.o_orderstatus = 'F')
LEFT JOIN LineItemSummary l ON l.l_orderkey = ro.o_orderkey
LEFT JOIN SupplierInfo si ON si.s_nationkey = n.n_nationkey
GROUP BY coalesce(c.c_name, 'Unknown Customer'), n.n_name
HAVING SUM(l.total_price) > 10000
ORDER BY supply_rank, total_orders DESC;
