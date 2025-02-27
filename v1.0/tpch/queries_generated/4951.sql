WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderstatus,
        r.total_revenue
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    WHERE 
        r.revenue_rank <= 10
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand, p.p_container
),
QualifiedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        SupplierParts ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_orderstatus,
    s.s_name AS supplier_name,
    s.unique_parts,
    o.total_revenue
FROM 
    TopOrders o
JOIN 
    QualifiedSuppliers s ON o.o_orderkey IN (
        SELECT l.l_orderkey
        FROM lineitem l
        WHERE l.l_partkey IN (
            SELECT ps.ps_partkey
            FROM partsupp ps
            WHERE ps.ps_suppkey = s.s_suppkey
        )
    )
ORDER BY 
    o.total_revenue DESC, s.unique_parts DESC;
