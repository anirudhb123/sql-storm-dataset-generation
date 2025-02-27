WITH SupplierPartAvailability AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_availqty DESC) as rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
FilteredSuppliers AS (
    SELECT 
        DISTINCT s.s_suppkey,
        s.s_name,
        COALESCE(NULLIF(s.s_acctbal, 0), (SELECT MAX(s2.s_acctbal) FROM supplier s2)) AS effective_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
RegionalPerformance AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(DISTINCT sp.s_suppkey) AS supplier_count,
        AVG(sp.ps_supplycost) AS avg_supply_cost
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        SupplierPartAvailability sp ON ps.ps_partkey = sp.p_partkey
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name,
    SUM(rp.total_avail_qty) AS regional_avail_qty,
    SUM(cp.total_spent) AS total_customer_spending,
    COUNT(DISTINCT cp.c_custkey) AS unique_customers
FROM 
    region r
LEFT JOIN 
    RegionalPerformance rp ON r.r_regionkey = cp.c_custkey
LEFT JOIN 
    CustomerOrderDetails cp ON cp.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = rp.n_nationkey)
GROUP BY 
    r.r_name
HAVING 
    regional_avail_qty > 500
ORDER BY 
    total_customer_spending DESC;
