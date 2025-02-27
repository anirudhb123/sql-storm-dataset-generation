WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
), SupplierPartPrices AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_supplycost,
        p.p_brand,
        p.p_type,
        p.p_size
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size BETWEEN 10 AND 50
), HighValueLines AS (
    SELECT
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_value,
        AVG(li.l_tax) AS average_tax
    FROM lineitem li
    GROUP BY li.l_orderkey
    HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
)
SELECT
    r.n_name AS nation,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
    AVG(sp.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT hp.l_orderkey) AS high_value_orders
FROM RankedOrders o
LEFT JOIN nation r ON r.n_nationkey = o.c_nationkey
LEFT JOIN SupplierPartPrices sp ON sp.ps_partkey IN (
    SELECT DISTINCT ps.ps_partkey 
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey 
    WHERE p.p_brand LIKE 'Brand%')
LEFT JOIN HighValueLines hp ON hp.l_orderkey = o.o_orderkey
WHERE o.rn = 1 AND (o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31')
GROUP BY r.n_name
ORDER BY total_orders DESC, average_supply_cost DESC
