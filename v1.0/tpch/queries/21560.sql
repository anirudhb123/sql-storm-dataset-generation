WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '1995-01-01' AND o.o_orderdate <= '1996-12-31'
),
CustomerOverview AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
),
SupplyDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROUND(AVG(ps.ps_supplycost), 2) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey AND l.l_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
RegionStats AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(coalesce(c.c_acctbal, 0)) AS total_account_balance,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    co.c_name,
    co.total_spent,
    sd.avg_supply_cost,
    rs.r_name,
    rs.nation_count,
    rs.total_account_balance,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No orders'
        ELSE 'Active'
    END AS customer_status
FROM RankedOrders ro
JOIN CustomerOverview co ON ro.o_orderkey = co.c_custkey
JOIN SupplyDetails sd ON sd.parts_supplied > 5
JOIN RegionStats rs ON rs.suppliers IS NOT NULL
WHERE ro.order_rank <= 10
  AND COALESCE(co.total_spent, 0) > 1000
ORDER BY ro.o_orderdate DESC, co.total_spent DESC;
