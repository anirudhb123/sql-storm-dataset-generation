WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_size,
        COALESCE(SUM(ps.ps_supplycost), 0) AS total_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice, p.p_size
    HAVING SUM(ps.ps_availqty) > 0
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE li.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
),
AggregatedResults AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT co.c_custkey) AS num_customers,
        AVG(co.total_order_value) AS avg_order_value,
        SUM(CASE WHEN li.l_returnflag = 'R' THEN li.l_quantity ELSE 0 END) AS total_returned_quantity
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN CustomerOrders co ON co.c_custkey = c.c_custkey
    LEFT JOIN lineitem li ON co.o_orderkey = li.l_orderkey
    WHERE r.r_name LIKE 'N%'
    GROUP BY r.r_name
)
SELECT 
    ar.r_name,
    ar.num_customers,
    ar.avg_order_value,
    hs.p_name,
    hs.p_retailprice,
    hs.total_supply_cost,
    rs.s_name,
    rs.rank,
    CASE 
        WHEN ar.total_returned_quantity IS NULL THEN 'NO RETURNS'
        WHEN ar.total_returned_quantity > 100 THEN '> 100 RETURNS'
        ELSE '<= 100 RETURNS'
    END AS return_status
FROM AggregatedResults ar
JOIN HighValueParts hs ON hs.p_retailprice > 100
JOIN RankedSuppliers rs ON rs.s_suppkey = ANY (
    SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = hs.p_partkey
)
WHERE ar.avg_order_value IS NOT NULL
ORDER BY ar.num_customers DESC, ar.avg_order_value DESC, hs.total_supply_cost ASC;