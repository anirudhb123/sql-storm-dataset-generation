WITH RankedSupplies AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty,
        ps.ps_supplycost * ps.ps_availqty AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        partsupp ps
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_customer_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), PartSuppliers AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) as rank_supplier
    FROM 
        part p
    LEFT JOIN 
        supplier s ON EXISTS (
            SELECT 1
            FROM partsupp ps
            WHERE ps.ps_partkey = p.p_partkey 
            AND ps.ps_suppkey = s.s_suppkey
            AND ps.ps_availqty > 0
        )
), Summary AS (
    SELECT 
        ps.p_partkey,
        ps.p_name,
        SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS adjusted_revenue,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity_sold,
        COALESCE(MAX(s.total_customer_spent), 0) AS max_spent_by_customer
    FROM 
        lineitem l
    JOIN 
        RankedSupplies rs ON l.l_partkey = rs.ps_partkey
    JOIN 
        part p ON p.p_partkey = rs.ps_partkey
    LEFT JOIN 
        CustomerOrders s ON s.total_orders > 0
    GROUP BY 
        ps.p_partkey, ps.p_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(sp.total_quantity_sold, 0) AS sold_quantity,
    COALESCE(sp.adjusted_revenue, 0) AS revenue,
    s.s_name AS supplier_name,
    rs.total_supply_cost,
    CASE 
        WHEN sp.revenue > 1000 THEN 'High' 
        WHEN sp.revenue BETWEEN 500 AND 1000 THEN 'Medium' 
        ELSE 'Low' 
    END AS revenue_category
FROM 
    part p
LEFT JOIN 
    Summary sp ON p.p_partkey = sp.p_partkey
LEFT JOIN 
    PartSuppliers ps ON p.p_partkey = ps.p_partkey AND ps.rank_supplier = 1
LEFT JOIN 
    RankedSupplies rs ON p.p_partkey = rs.ps_partkey AND rs.rn = 1
WHERE 
    p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
ORDER BY 
    revenue DESC, sold_quantity ASC;
