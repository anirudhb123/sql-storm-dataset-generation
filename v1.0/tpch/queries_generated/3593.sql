WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o1.o_totalprice) FROM orders o1 WHERE o1.o_orderstatus = o.o_orderstatus)
), SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), CustomerOrders AS (
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
)
SELECT 
    n.n_name AS nation,
    r.r_name AS region,
    COALESCE(SUM(CASE WHEN lo.rn IS NOT NULL THEN lo.o_totalprice ELSE 0 END), 0) AS total_order_value,
    COALESCE(SUM(ss.total_supply_cost), 0) AS total_supplier_cost,
    COALESCE(SUM(co.total_spent), 0) AS total_customer_spending
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedOrders lo ON lo.o_orderkey IN (SELECT DISTINCT o_orderkey FROM lineitem)
LEFT JOIN 
    SupplierSummary ss ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps JOIN part p ON ps.ps_partkey = p.p_partkey WHERE p.p_size > 15 LIMIT 1)
LEFT JOIN 
    CustomerOrders co ON co.total_spent > 1000
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_order_value DESC, total_supplier_cost DESC
LIMIT 10;
