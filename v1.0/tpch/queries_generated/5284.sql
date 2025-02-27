WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name, 
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_type, 
        ps.ps_supplycost, 
        ps.ps_availqty, 
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY ps.ps_supplycost DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    rs.nation_name, 
    hp.p_name, 
    hp.p_type, 
    hp.ps_supplycost, 
    co.o_orderkey, 
    co.o_totalprice, 
    co.o_orderdate
FROM 
    RankedSuppliers rs
JOIN 
    HighValueParts hp ON rs.s_suppkey = hp.ps_partkey
JOIN 
    CustomerOrders co ON co.o_orderkey = hp.ps_partkey
WHERE 
    rs.rank = 1 AND 
    hp.rank <= 5 AND 
    co.rank <= 3
ORDER BY 
    rs.nation_name, 
    hp.ps_supplycost DESC;
