WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name, 
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) as rnk
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT * 
    FROM RankedSuppliers 
    WHERE rnk <= 3
),
OrderSummaries AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueOrders AS (
    SELECT 
        li.l_orderkey,
        li.l_partkey,
        li.l_extendedprice,
        li.l_discount,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_value
    FROM lineitem li
    GROUP BY li.l_orderkey, li.l_partkey, li.l_extendedprice, li.l_discount
    HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 1000
)
SELECT 
    ts.nation_name, 
    ts.s_name AS supplier_name, 
    ou.c_name AS customer_name, 
    ou.total_order_value, 
    SUM(hvo.net_value) AS high_value_net 
FROM TopSuppliers ts
JOIN OrderSummaries ou ON ou.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = ts.s_nationkey ORDER BY c.c_acctbal DESC LIMIT 1)
JOIN HighValueOrders hvo ON hvo.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = ou.c_custkey)
GROUP BY ts.nation_name, ts.s_name, ou.c_name, ou.total_order_value
HAVING SUM(hvo.net_value) > 5000
ORDER BY ts.nation_name, high_value_net DESC;
