WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate) as order_level
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
), 
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > 10000
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rank
    FROM lineitem l
    WHERE l.l_discount > 0.1 AND l.l_discount < 0.5
),
CombinedData AS (
    SELECT 
        oh.o_orderkey,
        oh.o_custkey,
        s.s_name,
        pp.total_supply_cost,
        lc.l_extendedprice,
        lq.l_quantity,
        hvc.total_spent,
        ROW_NUMBER() OVER (PARTITION BY oh.o_orderkey ORDER BY lc.l_extendedprice DESC) AS order_rank
    FROM OrderHierarchy oh
    LEFT JOIN FilteredLineItems lc ON oh.o_orderkey = lc.l_orderkey
    JOIN SupplierPartDetails pp ON lc.l_partkey = pp.ps_partkey
    LEFT JOIN HighValueCustomers hvc ON oh.o_custkey = hvc.c_custkey
    LEFT JOIN (SELECT DISTINCT s_name FROM supplier) as sup ON pp.s_name = sup.s_name
)
SELECT 
    cdp.o_orderkey,
    cdp.o_custkey,
    COALESCE(cdp.s_name, 'UNKNOWN SUPPLIER') AS supplier_name,
    COALESCE(cdp.total_supply_cost, 0) AS total_supply_cost,
    SUM(cdp.l_extendedprice - (cdp.l_extendedprice * cdp.l_discount)) AS net_price,
    CASE 
        WHEN cdp.total_spent IS NULL THEN 'No Purchase'
        ELSE 'Valuable Customer'
    END AS customer_segment
FROM CombinedData cdp
WHERE cdp.order_rank = 1
GROUP BY cdp.o_orderkey, cdp.o_custkey, cdp.s_name, cdp.total_spent
HAVING SUM(cdp.l_extendedprice - (cdp.l_extendedprice * cdp.l_discount)) > 5000
ORDER BY net_price DESC, cdp.o_orderkey;
