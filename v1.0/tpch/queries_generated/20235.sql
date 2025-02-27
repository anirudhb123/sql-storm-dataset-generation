WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS rank,
        SUM(ps_availqty) AS total_availqty,
        AVG(ps_supplycost) AS avg_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(MAX(ps.ps_availqty), 0) AS max_availqty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    R.r_name,
    COUNT(DISTINCT NO_N.n_nationkey) AS nations_with_orders,
    SUM(COALESCE(PO.avg_supplycost, 0)) AS avg_supply_cost_of_top_suppliers,
    STRING_AGG(DISTINCT C.c_name) FILTER (WHERE C.total_orders > 0) AS customer_names
FROM 
    region R
LEFT JOIN 
    nation N ON N.n_regionkey = R.r_regionkey
LEFT JOIN 
    CustomerOrders C ON C.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = N.n_nationkey)
LEFT JOIN 
    PartDetails PO ON PO.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM RankedSuppliers S 
        WHERE S.rank = 1
    )
LEFT JOIN 
    orders O ON O.o_custkey = C.c_custkey
LEFT JOIN 
    lineitem L ON L.l_orderkey = O.o_orderkey
LEFT JOIN 
    partsupp PS ON PS.ps_partkey = L.l_partkey AND PS.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = N.n_nationkey)
WHERE 
    R.r_name IS NOT NULL 
GROUP BY 
    R.r_name
HAVING 
    SUM(COALESCE(L.l_discount, 0)) > 1000.00
ORDER BY 
    nations_with_orders DESC
LIMIT 10;
