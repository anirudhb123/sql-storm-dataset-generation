WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER(PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= date '2023-01-01' AND 
        o.o_orderdate < date '2023-12-31'
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
    ORDER BY 
        total_cost DESC
    LIMIT 5
)
SELECT 
    c.c_name,
    c.nation_name,
    COALESCE(ro.o_orderkey, 'No Orders') AS order_key,
    COALESCE(ro.o_totalprice, 0) AS total_price,
    ts.total_cost
FROM 
    CustomerDetails c
LEFT JOIN 
    RankedOrders ro ON c.order_count > 0 AND c.c_custkey = ro.o_orderkey
JOIN 
    TopSuppliers ts ON ts.ps_suppkey = c.c_custkey
WHERE 
    ts.total_cost IS NOT NULL OR c.order_count > 0
ORDER BY 
    ts.total_cost DESC, c.c_name;
