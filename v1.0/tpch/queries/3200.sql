WITH CustomerTotal AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ct.total_spent,
        RANK() OVER (ORDER BY ct.total_spent DESC) AS rank
    FROM 
        CustomerTotal ct
    JOIN 
        customer c ON ct.c_custkey = c.c_custkey
    WHERE 
        ct.total_spent IS NOT NULL
),
SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    nc.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_order_value,
    SUM(CASE 
            WHEN l.l_returnflag = 'Y' THEN 1 
            ELSE 0 
        END) AS total_returns,
    SUM(SP.total_supply_value) AS total_supplier_value,
    string_agg(CONCAT_WS(',', TOP.c_name, TOP.total_spent), '; ') AS top_customers
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation nc ON c.c_nationkey = nc.n_nationkey
LEFT JOIN 
    SupplierParts SP ON SP.s_suppkey = l.l_suppkey
LEFT JOIN 
    TopCustomers TOP ON TOP.c_custkey = c.c_custkey
WHERE 
    l.l_shipdate >= DATE '1997-01-01' AND 
    l.l_shipdate < DATE '1998-01-01'
GROUP BY 
    nc.n_name
ORDER BY 
    total_orders DESC
LIMIT 10;