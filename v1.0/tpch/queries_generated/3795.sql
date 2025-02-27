WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
    GROUP BY 
        c.c_custkey
),
PartSupplementInfo AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size > 10
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    c.c_name AS customer_name,
    c.c_acctbal AS customer_balance,
    COALESCE(cs.total_spent, 0) AS total_spent,
    COALESCE(cs.order_count, 0) AS order_count,
    p.p_name AS part_name,
    pi.total_available AS available_quantity,
    pi.total_cost AS supply_cost,
    ns.n_name AS nation_name,
    r.r_name AS region_name
FROM 
    customer c
LEFT JOIN 
    CustomerOrderSummary cs ON c.c_custkey = cs.c_custkey
JOIN 
    nation ns ON c.c_nationkey = ns.n_nationkey
JOIN 
    region r ON ns.n_regionkey = r.r_regionkey
INNER JOIN 
    partsupp ps ON ps.ps_suppkey IN (SELECT s_suppkey FROM RankedSuppliers WHERE rn = 1)
INNER JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    PartSupplementInfo pi ON ps.ps_partkey = pi.ps_partkey
WHERE 
    c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_mktsegment = c.c_mktsegment)
ORDER BY 
    total_spent DESC, customer_name ASC;
