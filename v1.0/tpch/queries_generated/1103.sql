WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
SupplierPartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        COALESCE(NULLIF(ps.ps_availqty, 0), 0) AS available_quantity
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    r.r_name,
    COALESCE(AVG(s.s_acctbal), 0) AS avg_account_balance,
    COUNT(DISTINCT h.o_orderkey) AS total_high_value_orders,
    SUM(spd.ps_supplycost * spd.available_quantity) AS total_supply_cost
FROM 
    region r
LEFT JOIN 
    RankedSuppliers s ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = s.s_suppkey)
LEFT JOIN 
    HighValueOrders h ON s.s_suppkey = h.o_custkey
LEFT JOIN 
    SupplierPartDetails spd ON s.s_suppkey = spd.p_partkey
WHERE 
    r.r_name LIKE '%North%'
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT h.o_orderkey) > 0 OR AVG(s.s_acctbal) > 10000
ORDER BY 
    total_high_value_orders DESC, avg_account_balance DESC;
