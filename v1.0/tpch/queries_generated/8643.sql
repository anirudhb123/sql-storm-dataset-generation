WITH SupplierPricing AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.total_cost,
        RANK() OVER (ORDER BY sp.total_cost DESC) AS rank
    FROM 
        SupplierPricing sp
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS order_total,
        COUNT(li.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        od.o_orderkey,
        od.o_orderdate,
        od.order_total,
        od.item_count,
        RANK() OVER (ORDER BY od.order_total DESC) AS rank
    FROM 
        OrderDetails od
)
SELECT 
    tu.rank AS supplier_rank,
    tu.s_name,
    to.rank AS order_rank,
    to.order_total,
    to.item_count
FROM 
    TopSuppliers tu
JOIN 
    TopOrders to ON tu.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem li ON ps.ps_partkey = li.l_partkey 
        WHERE li.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01')
        GROUP BY ps.ps_suppkey 
        ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC 
        LIMIT 1
    )
WHERE 
    tu.rank <= 10 AND to.rank <= 10
ORDER BY 
    supplier_rank, order_rank;
