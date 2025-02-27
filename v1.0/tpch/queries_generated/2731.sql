WITH SupplierCosts AS (
    SELECT 
        ps.suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(ps.ps_partkey) AS part_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.suppkey
), 
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sc.total_cost,
        sc.part_count
    FROM 
        supplier s
    INNER JOIN 
        SupplierCosts sc ON s.s_suppkey = sc.suppkey
    WHERE 
        sc.total_cost > (SELECT AVG(total_cost) FROM SupplierCosts)
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
RankedCustomers AS (
    SELECT 
        co.*,
        RANK() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM 
        CustomerOrders co
)

SELECT 
    ns.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    COALESCE(AVG(hv.total_cost), 0) AS avg_supplier_cost,
    SUM(CASE WHEN rc.rank < 10 THEN rc.order_count ELSE 0 END) AS top_customer_orders
FROM 
    nation ns
LEFT JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN 
    HighValueSuppliers hv ON s.s_suppkey = hv.s_suppkey
LEFT JOIN 
    RankedCustomers rc ON rc.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = ns.n_nationkey)
GROUP BY 
    ns.n_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 0
ORDER BY 
    nation_name;
