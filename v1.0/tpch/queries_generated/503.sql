WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
), FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATEADD(month, -3, CURRENT_DATE)
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
), CustomerRankings AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL
)

SELECT 
    p.p_partkey,
    p.p_name,
    r.r_name,
    rs.s_name AS top_supplier,
    cr.total_spent,
    cr.customer_rank,
    fo.net_revenue
FROM 
    part p
JOIN 
    region r ON p.p_partkey % 5 = r.r_regionkey   -- simulate distribution across regions
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = ps.ps_partkey AND rs.rn = 1
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    FilteredOrders fo ON fo.o_orderkey = ps.ps_partkey
LEFT JOIN 
    CustomerRankings cr ON cr.c_custkey = fo.o_orderkey % 1000   -- crude customer mapping
WHERE 
    p.p_size > 10
    AND (cr.customer_rank <= 10 OR cr.customer_rank IS NULL)
ORDER BY 
    cr.total_spent DESC NULLS LAST, 
    p.p_partkey;
