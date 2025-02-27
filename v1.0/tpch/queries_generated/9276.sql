WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
HighValuePartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_supplycost,
        (p.p_retailprice - ps.ps_supplycost) AS profit_margin
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_supplycost < p.p_retailprice
), 
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    r.r_name,
    COUNT(DISTINCT hs.ps_partkey) AS high_value_parts_count,
    SUM(CASE WHEN hs.profit_margin > 0 THEN hs.profit_margin ELSE 0 END) AS total_profit_margin,
    SUM(cc.order_count) AS total_customers
FROM 
    RankedSuppliers rs
JOIN 
    HighValuePartSuppliers hs ON rs.s_suppkey = hs.ps_suppkey
JOIN 
    nation n ON rs.n_nationkey = n.n_nationkey
JOIN 
    CustomerOrderCounts cc ON cc.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = hs.ps_suppkey))
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    total_profit_margin DESC, 
    high_value_parts_count DESC;
