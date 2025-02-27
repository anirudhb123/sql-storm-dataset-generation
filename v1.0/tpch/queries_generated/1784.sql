WITH RECURSIVE CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        c.c_name,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS most_recent_order
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(MAX(l.l_discount), 0) AS max_discount,
        STRING_AGG(DISTINCT r.r_name, ', ') AS regions
    FROM part p
    LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
    LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
),
AggregateResults AS (
    SELECT 
        p.p_name,
        p.p_retailprice,
        p.max_discount,
        si.num_parts,
        si.total_supplycost,
        CASE 
            WHEN p.max_discount > 0.2 THEN 'High Discount'
            ELSE 'Low Discount'
        END AS discount_category
    FROM PartDetails p
    LEFT JOIN SupplierInfo si ON p.p_partkey = si.s_suppkey
)
SELECT 
    co.c_name,
    ar.p_name,
    ar.p_retailprice,
    ar.max_discount,
    ar.discount_category,
    ar.num_parts,
    ar.total_supplycost
FROM CustomerOrders co
JOIN AggregateResults ar ON ar.p_name IN (
    SELECT p_name FROM AggregateResults WHERE total_supplycost > 10000
)
WHERE co.most_recent_order = 1
ORDER BY co.c_name, ar.p_name;
