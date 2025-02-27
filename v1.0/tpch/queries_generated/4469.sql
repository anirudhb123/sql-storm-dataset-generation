WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
),
TotalPriceByCustomer AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
),
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    ps.total_available_qty,
    ps.total_supply_cost,
    COALESCE(ts.total_spent, 0) AS total_spent,
    CASE 
        WHEN COUNT(DISTINCT rs.s_suppkey) > 5 THEN 'High Supply' 
        ELSE 'Low Supply' 
    END AS supply_category
FROM 
    part p
LEFT JOIN 
    PartSupplierInfo ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSupplier rs ON rs.s_nationkey = (
        SELECT n.n_nationkey
        FROM nation n
        WHERE n.n_name = 'USA'
    )
LEFT JOIN 
    TotalPriceByCustomer ts ON ts.c_custkey = (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_nationkey = rs.s_nationkey
        ORDER BY c.c_acctbal DESC
        LIMIT 1
    )
WHERE 
    p.p_retailprice > 20.00
AND 
    ps.total_available_qty IS NOT NULL
GROUP BY 
    p.p_name, ps.total_available_qty, ps.total_supply_cost, ts.total_spent
ORDER BY 
    total_supply_cost DESC;
