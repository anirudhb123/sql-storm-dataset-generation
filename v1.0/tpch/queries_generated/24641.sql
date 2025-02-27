WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
),
CustomerSupplier AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM customer c
    JOIN supplier s ON c.c_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY c.c_custkey, c.c_name, s.s_suppkey, s.s_name
),
TopCustomer AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        AVG(ord.o_totalprice) AS avg_order_value
    FROM CustomerSupplier cust
    JOIN RankedOrders ord ON cust.c_custkey = ord.o_orderkey
    GROUP BY cust.c_custkey, cust.c_name
    HAVING COUNT(ord.o_orderkey) > 2
)
SELECT 
    coalesce(c.c_name, 'Unknown Customer') AS customer_name,
    coalesce(s.s_name, 'Unknown Supplier') AS supplier_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    COUNT(DISTINCT li.l_orderkey) AS total_orders,
    ROW_NUMBER() OVER (ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS revenue_rank
FROM lineitem li
LEFT JOIN orders ord ON li.l_orderkey = ord.o_orderkey 
LEFT JOIN partsupp ps ON li.l_partkey = ps.ps_partkey 
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN TopCustomer c ON ord.o_custkey = c.c_custkey
WHERE li.l_returnflag = 'N' 
  AND li.l_shipmode IN ('AIR', 'TRUCK')
  AND (ps.ps_availqty IS NOT NULL OR ps.ps_supplycost IS NULL)
GROUP BY c.c_custkey, c.c_name, s.s_suppkey, s.s_name
HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 
    (SELECT AVG(total_supply_cost) FROM CustomerSupplier GROUP BY total_supply_cost HAVING COUNT(*) > 5)
ORDER BY total_revenue DESC
LIMIT 10;
