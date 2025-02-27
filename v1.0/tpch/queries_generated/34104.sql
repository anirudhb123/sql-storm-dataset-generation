WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) as order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
FilteredOrders AS (
    SELECT 
        c.c_name,
        SUM(co.o_totalprice) AS total_spent,
        COUNT(co.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE 
        co.order_rank <= 5
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierDetails AS (
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
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    fo.c_name,
    fo.total_spent,
    fo.order_count,
    sd.s_name AS supplier_name,
    sd.total_cost,
    lis.unique_parts,
    lis.total_quantity,
    lis.avg_price_after_discount
FROM 
    FilteredOrders fo
LEFT JOIN 
    LineItemSummary lis ON fo.c_name = (SELECT c.c_name FROM customer c WHERE c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = lis.l_orderkey LIMIT 1))
LEFT JOIN 
    SupplierDetails sd ON sd.total_cost > (
        SELECT AVG(sd2.total_cost) FROM SupplierDetails sd2
    )
WHERE 
    fo.total_spent > (
        SELECT AVG(total_spent) FROM FilteredOrders
    )
ORDER BY 
    fo.total_spent DESC, fo.order_count ASC;
