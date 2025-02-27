WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
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
        o.o_totalprice,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_retailprice,
        CONCAT(p.p_name, ' (', p.p_size, ' ', p.p_container, ')') AS full_description
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(o.o_totalprice) AS total_revenue,
    STRING_AGG(pd.full_description, ', ') AS part_descriptions
FROM 
    RankedSuppliers s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    CustomerOrders o ON l.l_orderkey = o.o_orderkey
JOIN 
    PartDetails pd ON l.l_partkey = pd.p_partkey
WHERE 
    s.rank = 1 AND 
    o.order_rank <= 5
GROUP BY 
    r.r_name, n.n_name, s.s_name
ORDER BY 
    total_revenue DESC;
