WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' 
        AND o.o_orderdate < DATE '2023-01-01'
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(*) AS supplier_count
    FROM 
        partsupp ps
    WHERE 
        ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
    GROUP BY 
        ps.ps_partkey
),
CustomerPreferences AS (
    SELECT 
        c.c_nationkey,
        c.c_mktsegment,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_nationkey, c.c_mktsegment
    HAVING 
        total_orders > 10
)
SELECT 
    r.r_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
    AVG(so.total_available) AS avg_availability,
    COUNT(DISTINCT co.o_orderkey) AS count_orders,
    NC.n_name AS nation_name
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierAvailability sa ON EXISTS (SELECT 1 FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#49'))
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F' AND o.o_orderpriority = 'High')
LEFT JOIN 
    lineitem li ON li.l_orderkey = ro.o_orderkey
LEFT JOIN 
    CustomerPreferences co ON co.c_nationkey = n.n_nationkey
WHERE 
    r.r_name IS NOT NULL
    AND r.r_comment IS NOT NULL
    AND (n.n_name LIKE 'A%' OR n.n_name LIKE 'B%')
GROUP BY 
    r.r_name, NC.n_name
ORDER BY 
    total_sales DESC, avg_availability DESC
LIMIT 100;
