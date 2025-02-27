WITH SupplierCosts AS (
    SELECT 
        ps.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS price_rank
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01'
        AND l.l_shipdate <= DATE '2023-12-31'
)
SELECT 
    s.s_name,
    s.s_acctbal,
    COALESCE(SC.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(CO.total_orders, 0) AS total_orders,
    COALESCE(CO.total_spent, 0) AS total_spent,
    FL.price_rank,
    SUM(FL.l_extendedprice) AS total_extended_price
FROM 
    supplier s
LEFT JOIN 
    SupplierCosts SC ON s.s_suppkey = SC.s_suppkey
LEFT JOIN 
    CustomerOrders CO ON s.s_nationkey = CO.c_custkey
LEFT JOIN 
    FilteredLineItems FL ON s.s_suppkey = FL.l_suppkey
WHERE 
    s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
GROUP BY 
    s.s_suppkey, FL.price_rank
ORDER BY 
    total_spent DESC, total_supply_cost DESC;
