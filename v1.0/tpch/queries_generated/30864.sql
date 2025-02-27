WITH RecursivePartSupplier AS (
    SELECT 
        ps_partkey,
        ps_suppkey,
        ps_availqty,
        ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS rn
    FROM partsupp
    WHERE ps_availqty > 0
),
HighValueCustomers AS (
    SELECT 
        c_custkey,
        c_name,
        SUM(o_totalprice) AS total_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c_custkey, c_name
    HAVING SUM(o_totalprice) > 50000
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name, r.r_name
),
FinalOrders AS (
    SELECT 
        o.o_orderkey,
        COUNT(li.l_orderkey) AS line_count,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_price,
        MAX(li.l_shipdate) AS latest_shipdate
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE li.l_returnflag = 'N' AND li.l_linestatus = 'O'
    GROUP BY o.o_orderkey
)
SELECT 
    r.region_name,
    s.s_name,
    COALESCE(p.p_name, 'Unknown') AS part_name,
    hf.total_value,
    f.line_count,
    f.total_price,
    f.latest_shipdate
FROM SupplierRegion s
LEFT JOIN RecursivePartSupplier p ON s.s_suppkey = p.ps_suppkey AND p.rn = 1
JOIN HighValueCustomers hf ON hf.total_value > s.total_cost
JOIN FinalOrders f ON f.line_count = (SELECT MAX(line_count) FROM FinalOrders)
WHERE s.total_cost > 100000
ORDER BY s.region_name, hf.total_value DESC;
