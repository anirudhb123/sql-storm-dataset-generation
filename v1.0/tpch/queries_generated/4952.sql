WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS total_parts,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        c.c_name,
        o.o_orderdate,
        DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 100000
)
SELECT 
    NSS.n_name AS nation,
    SUM(S.total_supply_cost) AS total_supply_cost,
    COUNT(DISTINCT C.c_custkey) AS total_customers,
    AVG(C.total_spent) AS avg_spending,
    STRING_AGG(DISTINCT C.c_name, ', ') AS high_value_customers
FROM 
    nation NSS
LEFT JOIN 
    SupplierSummary S ON NSS.n_nationkey = S.s_nationkey
LEFT JOIN 
    HighValueCustomers C ON NSS.n_nationkey = C.c_nationkey
WHERE 
    S.total_parts IS NOT NULL
GROUP BY 
    NSS.n_name
HAVING 
    SUM(S.total_supply_cost) IS NOT NULL AND AVG(C.total_spent) IS NOT NULL
ORDER BY 
    total_supply_cost DESC;
