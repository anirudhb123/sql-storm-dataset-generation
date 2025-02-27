WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= date '2020-01-01'
), 
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        RankedOrders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        MAX(ps.ps_supplycost) AS max_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
OrderLineDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(*) AS line_count,
        AVG(l.l_tax) AS average_tax
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    c.c_name,
    COALESCE(cd.total_orders, 0) AS total_orders,
    COALESCE(cd.total_spent, 0) AS total_spent,
    sp.total_available_quantity,
    sp.max_supply_cost,
    o.net_revenue,
    o.line_count,
    o.average_tax,
    RANK() OVER (ORDER BY COALESCE(cd.total_spent, 0) DESC) AS customer_rank
FROM 
    CustomerDetails cd
JOIN 
    SupplierParts sp ON sp.ps_partkey = (
        SELECT p.p_partkey
        FROM part p
        WHERE p.p_retailprice > 100.00
        ORDER BY p.p_retailprice DESC 
        LIMIT 1
    )
LEFT JOIN 
    OrderLineDetails o ON o.l_orderkey IN (
        SELECT o_orderkey 
        FROM RankedOrders 
        WHERE order_rank = 1
    )
WHERE 
    cd.total_orders > 0
ORDER BY 
    customer_rank, total_spent DESC;
