
WITH CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spending,
        AVG(o.o_totalprice) AS average_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), SupplierPartStats AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        RANK() OVER (ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
)
SELECT 
    c.c_name,
    COALESCE(cos.order_count, 0) AS number_of_orders,
    COALESCE(cos.total_spending, 0) AS total_spent,
    COALESCE(cos.average_order_value, 0) AS avg_order_value,
    sp.ps_partkey,
    sp.total_available_quantity,
    sp.total_supply_cost,
    CASE 
        WHEN sp.total_available_quantity IS NULL THEN 'Out of Stock'
        ELSE 'In Stock' 
    END AS stock_status
FROM 
    customer c
LEFT JOIN 
    CustomerOrderStats cos ON c.c_custkey = cos.c_custkey
LEFT JOIN 
    SupplierPartStats sp ON sp.ps_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = (
            SELECT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_orderkey = (
                SELECT o.o_orderkey 
                FROM RankedOrders o 
                WHERE o.price_rank = 1
            )
        )
    )
WHERE 
    c.c_acctbal > 10000
ORDER BY 
    cos.total_spending DESC, 
    c.c_name;
