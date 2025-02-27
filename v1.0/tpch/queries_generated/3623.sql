WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2024-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_supplycost,
        ps.ps_availqty
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
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
),
FilteredProducts AS (
    SELECT 
        pp.ps_partkey,
        pp.p_name,
        pp.supplier_name,
        pp.ps_supplycost,
        pp.ps_availqty,
        CASE 
            WHEN pp.ps_availqty < 100 THEN 'Low Stock'
            WHEN pp.ps_availqty BETWEEN 100 AND 500 THEN 'Medium Stock'
            ELSE 'High Stock'
        END AS stock_status
    FROM 
        SupplierParts pp
    WHERE 
        pp.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
)
SELECT 
    co.c_name,
    co.total_spent,
    fp.p_name,
    fp.stock_status,
    fp.ps_supplycost
FROM 
    CustomerOrders co
LEFT OUTER JOIN 
    FilteredProducts fp ON co.c_custkey = (
        SELECT 
            DISTINCT o.o_custkey 
        FROM 
            orders o 
        WHERE 
            o.o_orderkey IN (SELECT o_orderkey FROM RankedOrders WHERE order_rank = 1)
    )
WHERE 
    co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
ORDER BY 
    co.total_spent DESC, 
    fp.stock_status;
