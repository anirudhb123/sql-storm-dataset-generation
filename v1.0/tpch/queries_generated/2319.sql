WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING 
        SUM(o.o_totalprice) > 10000
),
PartDetails AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    c.c_name,
    c.c_acctbal,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    p.p_name AS part_name,
    p.total_supply_cost,
    CASE 
        WHEN s.rnk IS NOT NULL THEN 'Ranked Supplier'
        ELSE 'Unranked'
    END AS supplier_status,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    HighValueCustomers c
LEFT JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN 
    RankedSuppliers s ON s.rnk = 1 AND s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_type LIKE 'Special%'))
INNER JOIN 
    PartDetails p ON p.p_partkey = l.l_partkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    c.c_name, c.c_acctbal, s.s_name, p.p_name, p.total_supply_cost, s.rnk
ORDER BY 
    total_revenue DESC
LIMIT 50;
