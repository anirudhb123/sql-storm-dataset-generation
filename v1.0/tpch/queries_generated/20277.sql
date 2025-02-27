WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank,
        SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY o.o_custkey) AS total_spent
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_mktsegment = 'BUILDING')
    GROUP BY 
        c.c_custkey
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplyworth
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps.ps_supplycost * ps.ps_availqty) FROM partsupp ps)
), 
QuestionableOrders AS (
    SELECT 
        DISTINCT o.o_orderkey, 
        o.o_orderstatus,
        CASE 
            WHEN o.o_totalprice > 10000 THEN 'High Value'
            ELSE 'Normal'
        END AS order_value_category
    FROM 
        orders o
    WHERE 
        EXISTS (
            SELECT 1 
            FROM lineitem l 
            WHERE l.l_orderkey = o.o_orderkey 
            AND l.l_returnflag IS NULL
        )
)

SELECT 
    n.n_name AS nation,
    r.r_name AS region,
    COUNT(DISTINCT q.o_orderkey) AS questionable_order_count,
    SUM(h.total_spent) AS total_spent_by_high_value_customers,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.total_supplyworth, ')'), ', ') AS supplier_details
FROM 
    QuestionableOrders q
LEFT JOIN 
    RankedOrders r ON q.o_orderkey = r.o_orderkey
JOIN 
    HighValueCustomers h ON h.order_count > 1
JOIN 
    supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN lineitem l ON ps.ps_partkey = l.l_partkey WHERE l.l_quantity > 100)
JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = h.c_custkey LIMIT 1)
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
WHERE 
    (r.r_name IS NOT NULL OR q.order_value_category = 'High Value')
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    nation, region;
