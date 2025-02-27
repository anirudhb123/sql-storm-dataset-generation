WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_within_nation
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        total_supplycost,
        avg_acctbal
    FROM 
        SupplierStats s
    WHERE 
        s.total_supplycost > (SELECT AVG(total_supplycost) FROM SupplierStats)
)
SELECT 
    co.c_name,
    co.total_spent,
    co.order_count,
    hs.s_name AS top_supplier,
    hs.total_supplycost
FROM 
    CustomerOrders co
LEFT JOIN 
    lineitem li ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name = co.c_name)
LEFT JOIN 
    HighValueSuppliers hs ON li.l_suppkey = hs.s_suppkey
WHERE 
    co.order_count > 5
    AND co.rank_within_nation = 1
ORDER BY 
    co.total_spent DESC, co.c_name
LIMIT 10;
