WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) as rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
),
PartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100.00
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS number_of_orders,
        STRING_AGG(DISTINCT o.o_orderpriority, ', ') AS order_priorities
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name,
    rs.s_name AS top_supplier,
    ps.total_cost,
    co.total_spent,
    co.number_of_orders,
    co.order_priorities
FROM 
    part p
LEFT JOIN 
    PartSuppliers ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON rs.rnk = 1
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Germany') LIMIT 1)
WHERE 
    ps.total_cost IS NOT NULL OR co.total_spent IS NOT NULL
ORDER BY 
    p.p_name;
