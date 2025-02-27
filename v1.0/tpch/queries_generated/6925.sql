WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) -- Supplier with above-average account balance
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
RankedSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.p_partkey,
        sp.p_name,
        ROW_NUMBER() OVER (PARTITION BY sp.p_partkey ORDER BY sp.ps_supplycost ASC) AS rn
    FROM 
        SupplierParts sp
)
SELECT 
    co.c_name AS customer_name,
    co.total_spent AS total_amount_spent,
    rs.s_name AS supplier_name,
    rs.p_name AS part_name,
    rs.ps_supplycost AS supply_cost
FROM 
    CustomerOrders co
JOIN 
    RankedSuppliers rs ON rs.rn = 1 -- select the cheapest supplier for each part
WHERE 
    co.total_spent > 1000 -- filter customers who spent more than 1000
ORDER BY 
    co.total_spent DESC, 
    rs.supply_cost ASC;
