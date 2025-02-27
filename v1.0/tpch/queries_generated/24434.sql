WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2020-01-01'
),
CustomerNations AS (
    SELECT 
        c.c_custkey,
        n.n_name,
        n.n_regionkey,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'Unknown Account Balance'
            WHEN c.c_acctbal < 1000 THEN 'Low Balance'
            ELSE 'Sufficient Balance'
        END AS Balance_Status
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
OrderLineStats AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        MAX(l.l_shipdate) AS last_ship_date
    FROM lineitem l
    GROUP BY l.l_orderkey
),
FinalAnalysis AS (
    SELECT 
        c.n_nationkey,
        c.n_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(cl.total_sales) AS avg_sales_per_order,
        ARRAY_AGG(DISTINCT CONCAT(p.p_name, ': ', p.p_partkey)) AS high_value_parts
    FROM CustomerNations c
    LEFT JOIN RankedOrders o ON c.c_custkey = o.o_custkey AND o.order_rank <= 10
    LEFT JOIN OrderLineStats cl ON o.o_orderkey = cl.l_orderkey
    LEFT JOIN HighValueParts p ON o.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey
    )
    GROUP BY c.n_nationkey, c.n_name
    HAVING total_order_value IS NOT NULL
    ORDER BY total_order_value DESC
)
SELECT 
    f.n_name,
    f.total_order_value,
    f.order_count,
    f.avg_sales_per_order,
    STRING_AGG(DISTINCT hp.p_name, ', ') AS high_value_parts_names
FROM FinalAnalysis f
LEFT JOIN HighValueParts hp ON f.high_value_parts @> ARRAY[h.p_partkey]; 
