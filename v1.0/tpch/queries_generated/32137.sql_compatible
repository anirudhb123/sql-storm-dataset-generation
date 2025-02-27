
WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ps.ps_partkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        1 AS level
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 0
    
    UNION ALL
    
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ps.ps_partkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        sc.level + 1
    FROM 
        SupplyChain sc
    JOIN 
        supplier s ON sc.s_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 0 AND sc.level < 5
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus <> 'X' OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cs.total_spent,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS rn
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_custkey = c.c_custkey
    WHERE 
        cs.total_spent IS NOT NULL
)
SELECT 
    p.p_partkey,
    p.p_name,
    SUM(ps.ps_availqty) AS total_available,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    COUNT(DISTINCT tc.c_custkey) AS total_customers
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    TopCustomers tc ON tc.c_custkey = s.s_nationkey
WHERE 
    p.p_retailprice > 100.00
GROUP BY 
    p.p_partkey, p.p_name, n.n_name
HAVING 
    SUM(ps.ps_availqty) > 0
ORDER BY 
    total_available DESC
LIMIT 10;
