WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
PartAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N' AND l.l_linestatus = 'F'
    GROUP BY 
        l.l_orderkey, l.l_partkey
)
SELECT 
    p.p_name,
    pa.total_avail_qty,
    COALESCE(SUM(f.net_revenue), 0) AS total_revenue,
    COALESCE(AVG(co.total_spent), 0) AS avg_customer_spending,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count
FROM 
    part p
LEFT JOIN 
    PartAvailability pa ON p.p_partkey = pa.ps_partkey
LEFT JOIN 
    FilteredLineItems f ON p.p_partkey = f.l_partkey
LEFT JOIN 
    RankedSuppliers rs ON rs.rank = 1 AND rs.s_suppkey IN (
        SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey
    )
LEFT JOIN 
    CustomerOrders co ON co.c_custkey IN (
        SELECT o.o_custkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_partkey = p.p_partkey
    )
WHERE 
    p.p_retailprice > 50.00
GROUP BY 
    p.p_name, pa.total_avail_qty
ORDER BY 
    total_revenue DESC, p.p_name;
