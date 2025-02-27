WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_partkey,
        p.p_brand,
        (ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY (ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_supplier
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
TotalOrders AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
CustomerRegions AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_nationkey,
        r.r_regionkey
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cr.c_name AS customer_name,
    tr.r_regionkey,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    AVG(rs.total_cost) AS avg_supplier_cost,
    SUM(to.total_spent) AS total_spent_by_customer
FROM 
    CustomerRegions cr
JOIN 
    TotalOrders to ON cr.c_custkey = to.o_custkey
JOIN 
    RankedSuppliers rs ON cr.c_custkey = rs.s_suppkey
WHERE 
    rs.rank_supplier <= 5
GROUP BY 
    cr.c_name, tr.r_regionkey
ORDER BY 
    total_spent_by_customer DESC
LIMIT 10;
