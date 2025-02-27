WITH SupplierPart AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
),
CustomerOrder AS (
    SELECT 
        c.c_custkey,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, o.o_orderkey
),
RankedSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.p_partkey,
        sp.p_name,
        sp.ps_availqty,
        sp.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY sp.p_partkey ORDER BY sp.ps_supplycost ASC) AS rank
    FROM 
        SupplierPart sp
)

SELECT 
    cs.c_custkey,
    cs.total_spent,
    rs.p_partkey,
    rs.p_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
    COUNT(DISTINCT o.o_orderkey) AS distinct_orders,
    AVG(rs.ps_supplycost) AS avg_supply_cost
FROM 
    CustomerOrder cs
LEFT JOIN 
    orders o ON cs.o_orderkey = o.o_orderkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
INNER JOIN 
    RankedSuppliers rs ON cs.total_spent > 1000 AND rs.rank = 1
GROUP BY 
    cs.c_custkey, cs.total_spent, rs.p_partkey, rs.p_name
HAVING 
    AVG(rs.ps_supplycost) > 50
ORDER BY 
    cs.total_spent DESC, total_returned ASC;
