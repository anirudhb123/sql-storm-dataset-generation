WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2021-01-01'
),
OrderLineItems AS (
    SELECT 
        o.custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        RANK() OVER (PARTITION BY o.custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_spent
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate >= DATE '2021-01-01'
    GROUP BY 
        o.custkey
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.total_available,
        sp.avg_supplycost,
        RANK() OVER (ORDER BY sp.total_available DESC) AS rank_supplier
    FROM 
        SupplierParts sp
)
SELECT 
    co.c_name,
    co.o_orderkey,
    co.o_totalprice,
    o.total_spent,
    ts.total_available,
    ts.avg_supplycost,
    CASE 
        WHEN co.rank_order <= 5 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category,
    CASE 
        WHEN ts.rank_supplier <= 10 THEN 'Preferred Supplier'
        ELSE 'Other Supplier'
    END AS supplier_category
FROM 
    CustomerOrders co
LEFT JOIN 
    OrderLineItems o ON co.c_custkey = o.custkey
LEFT JOIN 
    TopSuppliers ts ON o.custkey = ts.s_suppkey
WHERE 
    ts.total_available IS NOT NULL
ORDER BY 
    co.o_totalprice DESC,
    o.order_count DESC;
