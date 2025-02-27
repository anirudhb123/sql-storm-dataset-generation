WITH PartSupplierSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('F', 'P') OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.total_available_qty,
    ps.total_supply_cost,
    co.customer_name,
    co.total_orders,
    co.total_spent,
    sr.supplier_rank
FROM 
    PartSupplierSummary ps
LEFT JOIN 
    CustomerOrderSummary co ON ps.total_supply_cost > co.total_spent
LEFT JOIN 
    RankedSuppliers sr ON ps.total_supply_cost < sr.supplier_rank * 1000
WHERE 
    ps.total_available_qty IS NOT NULL
ORDER BY 
    ps.total_supply_cost DESC, co.total_spent ASC
LIMIT 100;
