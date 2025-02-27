WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueSuppliers AS (
    SELECT 
        r.r_name AS region, 
        ns.n_name AS nation,
        hs.s_suppkey, 
        hs.s_name, 
        hs.total_supply_value
    FROM 
        RankedSuppliers hs
    JOIN 
        nation ns ON hs.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        hs.rank <= 5
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cus.c_name, 
    cus.order_count, 
    cus.total_spent,
    sup.region,
    sup.nation,
    sup.s_name,
    sup.total_supply_value
FROM 
    CustomerOrderSummary cus
JOIN 
    HighValueSuppliers sup ON cus.c_custkey = (SELECT c.c_custkey 
                                               FROM customer c 
                                               WHERE c.c_nationkey = (SELECT n.n_nationkey 
                                                                       FROM nation n 
                                                                       JOIN supplier s ON n.n_nationkey = s.s_nationkey 
                                                                       WHERE s.s_suppkey = sup.s_suppkey 
                                                                       LIMIT 1))
ORDER BY 
    sup.region, sup.nation, cus.total_spent DESC;
