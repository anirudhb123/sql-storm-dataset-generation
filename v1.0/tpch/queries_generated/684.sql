WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_customerkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount,
        AVG(l.l_tax) AS avg_tax_rate
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    COALESCE(li.total_price_after_discount, 0) AS total_price_after_discount,
    COALESCE(si.total_supplycost, 0) AS supplier_total_cost,
    r.r_name AS region_name
FROM RankedOrders o
LEFT JOIN LineItemStats li ON o.o_orderkey = li.l_orderkey
LEFT JOIN SupplierStats si ON o.o_orderkey IN (
    SELECT li.l_orderkey 
    FROM lineitem li 
    WHERE li.l_returnflag = 'R'
) 
JOIN nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
JOIN region r ON r.r_regionkey = n.n_regionkey
WHERE o.o_totalprice > (
    SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
) AND n.n_name IS NOT NULL
ORDER BY o.o_orderdate DESC, o.o_orderkey;
