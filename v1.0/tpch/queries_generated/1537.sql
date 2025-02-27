WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplies AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FilteredRegions AS (
    SELECT 
        r.r_regionkey, 
        r.r_name 
    FROM 
        region r 
    WHERE 
        r.r_comment IS NOT NULL
)
SELECT 
    c.c_name AS customer_name,
    ct.total_orders,
    ct.total_spent,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    ps.total_available,
    ps.total_supply_cost,
    r.r_name AS region_name
FROM 
    CustomerOrders ct
JOIN 
    lineitem l ON ct.c_custkey = l.l_orderkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rnk = 1
LEFT JOIN 
    FilteredRegions r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = ct.c_custkey))
WHERE 
    ct.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
ORDER BY 
    ct.total_spent DESC, 
    customer_name ASC;
