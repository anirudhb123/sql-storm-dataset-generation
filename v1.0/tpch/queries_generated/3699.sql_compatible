
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_size,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_available
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice, p.p_size
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_name AS r_regionname,
    COUNT(DISTINCT c.c_custkey) AS active_customers,
    SUM(cp.total_spent) AS total_revenue,
    AVG(p.total_available) AS avg_available_parts,
    COUNT(DISTINCT os.o_orderkey) AS total_orders
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    CustomerOrders cp ON c.c_custkey = cp.c_custkey
LEFT JOIN 
    FilteredParts p ON p.p_retailprice > 100.00
LEFT JOIN 
    OrderDetails os ON c.c_custkey = os.o_orderkey
LEFT JOIN 
    RankedSuppliers rs ON c.c_custkey = rs.s_suppkey
WHERE 
    rs.rank = 1 AND (cp.total_spent IS NOT NULL OR p.total_available > 0)
GROUP BY 
    r.r_name
HAVING 
    AVG(p.total_available) > 50
ORDER BY 
    total_revenue DESC;
