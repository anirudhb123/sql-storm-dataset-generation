
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01' 
      AND o.o_orderdate < DATE '1997-01-01'
),
SupplierPartSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(ss.parts_supplied, 0) AS parts_supplied,
    COALESCE(ss.total_supply_value, 0) AS total_supply_value,
    COALESCE(cs.total_orders, 0) AS total_orders,
    COALESCE(cs.total_spent, 0) AS total_spent,
    nr.region_name
FROM part p
LEFT JOIN SupplierPartSummary ss ON EXISTS (
    SELECT 1 
    FROM partsupp ps 
    WHERE ps.ps_partkey = p.p_partkey AND ps.ps_supplycost > 100
) 
LEFT JOIN CustomerSummary cs ON EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.o_totalprice > 5000 AND o.o_orderkey IN (
        SELECT o2.o_orderkey 
        FROM orders o2 
        WHERE o2.o_custkey = cs.c_custkey
    )
)
LEFT JOIN NationRegion nr ON EXISTS (
    SELECT 1 
    FROM supplier s 
    WHERE s.s_nationkey = (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_name = 'USA'
    ) AND s.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = p.p_partkey
    )
)
WHERE p.p_retailprice BETWEEN 100 AND 500
ORDER BY p.p_partkey, total_spent DESC;
