WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
), CustomerOrders AS (
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
), HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
), SupplierPartStats AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_retailprice,
    COALESCE(ss.supplier_count, 0) AS supplier_count,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    cu.total_spent,
    r.r_name AS region_name
FROM 
    part p
LEFT JOIN 
    SupplierPartStats ss ON p.p_partkey = ss.ps_partkey
JOIN 
    RankedSuppliers rs ON ss.supplier_count > 5 AND rs.rn = 1
JOIN 
    nation n ON rs.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerOrders cu ON cu.c_custkey IN (SELECT DISTINCT o.o_custkey FROM HighValueOrders o)
WHERE 
    p.p_retailprice BETWEEN 10.00 AND 100.00
ORDER BY 
    p.p_partkey;
