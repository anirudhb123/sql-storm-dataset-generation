WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_totalprice,
        ro.o_orderdate
    FROM RankedOrders ro
    WHERE ro.rn <= 10
),
CustomerAgg AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
),
PartSupplierAgg AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 5000
)

SELECT 
    to.o_orderkey,
    to.o_totalprice,
    ca.c_name,
    psa.supplier_value
FROM TopOrders to
JOIN CustomerAgg ca ON to.o_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_custkey = ca.c_custkey
    )
JOIN PartSupplierAgg psa ON to.o_orderkey IN (
        SELECT l.l_orderkey
        FROM lineitem l
        WHERE l.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps)
    )
ORDER BY to.o_totalprice DESC, ca.total_spent DESC;
