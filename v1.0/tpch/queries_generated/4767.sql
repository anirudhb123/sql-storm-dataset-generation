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
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' 
        AND o.o_orderdate < '2024-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        COUNT(*) AS total_supply
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(sp.total_supply, 0) AS total_supply,
        (p.p_retailprice * COALESCE(sp.total_supply, 0)) AS revenue_generated
    FROM 
        part p
    LEFT JOIN 
        SupplierParts sp ON p.p_partkey = sp.ps_partkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT co.c_custkey) AS total_customers,
    SUM(co.total_order_value) AS total_order_value,
    SUM(pd.revenue_generated) AS total_revenue_generated,
    AVG(s.s_acctbal) AS average_supplier_balance
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    PartDetails pd ON s.s_suppkey = pd.total_supply
LEFT JOIN 
    CustomerOrders co ON co.o_orderkey IS NOT NULL
WHERE 
    r.r_name IS NOT NULL 
    AND s.s_acctbal > 1000 
GROUP BY 
    r.r_name
HAVING 
    SUM(co.total_order_value) > 50000
ORDER BY 
    total_order_value DESC;
