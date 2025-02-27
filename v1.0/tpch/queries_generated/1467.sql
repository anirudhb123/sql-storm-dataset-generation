WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 1000
    GROUP BY s.s_suppkey, s.s_name
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    rd.o_orderkey,
    rd.o_orderdate,
    rd.o_totalprice,
    rs.s_name,
    cs.total_spent,
    cs.total_orders,
    CASE 
        WHEN cs.total_orders IS NULL THEN 'No Orders'
        WHEN cs.total_orders < 5 THEN 'Low Activity'
        ELSE 'Active Customer'
    END AS customer_activity,
    COALESCE(sd.total_supply_cost, 0) AS supplier_cost
FROM RankedOrders rd
LEFT JOIN SupplierDetails sd ON sd.s_suppkey IN (
    SELECT DISTINCT l.l_suppkey
    FROM lineitem l
    WHERE l.l_orderkey = rd.o_orderkey
)
LEFT JOIN CustomerStats cs ON cs.c_custkey = (
    SELECT o.o_custkey 
    FROM orders o 
    WHERE o.o_orderkey = rd.o_orderkey
)
WHERE rd.order_rank <= 10
ORDER BY rd.o_orderdate DESC, rd.o_totalprice DESC;
