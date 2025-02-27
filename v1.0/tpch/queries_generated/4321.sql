WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(ps.ps_partkey) AS num_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), 
CustomerTotalSpend AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    sd.s_name AS supplier,
    cs.c_name AS customer,
    cs.total_spent,
    SUM(CASE WHEN li.l_returnflag = 'R' THEN li.l_extendedprice * (1 - li.l_discount) ELSE 0 END) AS total_returned_value,
    COUNT(DISTINCT ord.o_orderkey) AS order_count
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierDetails sd ON n.n_nationkey = sd.s_nationkey
LEFT JOIN RankedOrders ord ON ord.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_orderdate > DATEADD(YEAR, -1, GETDATE())
    AND ord.rn <= 5
)
LEFT JOIN lineitem li ON li.l_orderkey = ord.o_orderkey
JOIN CustomerTotalSpend cs ON cs.c_custkey = ord.o_custkey
WHERE sd.num_parts > 10 AND cs.total_spent > 1000
GROUP BY r.r_name, n.n_name, sd.s_name, cs.c_name, cs.total_spent
ORDER BY total_returned_value DESC, order_count DESC;
