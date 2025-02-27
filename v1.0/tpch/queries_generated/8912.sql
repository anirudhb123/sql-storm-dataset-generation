WITH RankedOrders AS (
    SELECT 
        o_orderkey,
        o_custkey,
        o_totalprice,
        o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS order_rank
    FROM 
        orders
    WHERE 
        o_orderstatus = 'O'
), CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS average_spent
    FROM 
        customer c
    JOIN 
        RankedOrders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), SupplierPartStats AS (
    SELECT
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), CombinedStats AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_orders,
        cs.total_spent,
        cs.average_spent,
        sps.total_suppliers,
        sps.total_available_quantity,
        sps.average_supply_cost
    FROM 
        CustomerSummary cs
    LEFT JOIN 
        SupplierPartStats sps ON cs.total_orders > 5
)
SELECT 
    c.c_name,
    c.total_orders,
    c.total_spent,
    c.average_spent,
    COALESCE(c.total_suppliers, 0) AS total_suppliers,
    COALESCE(c.total_available_quantity, 0) AS total_available_quantity,
    COALESCE(c.average_supply_cost, 0) AS average_supply_cost
FROM 
    CombinedStats c
WHERE 
    c.total_spent > 1000
ORDER BY 
    c.total_orders DESC, c.total_spent DESC
LIMIT 10;
