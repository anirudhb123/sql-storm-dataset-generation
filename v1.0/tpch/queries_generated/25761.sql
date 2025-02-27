WITH PartStatistics AS (
    SELECT 
        p_brand,
        p_type,
        COUNT(*) AS part_count,
        AVG(p_retailprice) AS avg_price,
        STRING_AGG(DISTINCT p_name, ', ') AS part_names
    FROM 
        part
    GROUP BY 
        p_brand, p_type
),
SupplierTopParts AS (
    SELECT 
        s.s_name,
        ps.ps_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY p.p_retailprice DESC) AS part_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_items
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    ps.s_name,
    p.part_count,
    p.avg_price,
    c.c_name,
    c.total_revenue,
    c.total_items,
    STRING_AGG(DISTINCT ps.p_name, ', ') AS top_parts
FROM 
    SupplierTopParts ps
JOIN 
    PartStatistics p ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE CONCAT(p.p_brand, ' ', p.p_type) LIKE CONCAT('%', p_type, '%'))
JOIN 
    CustomerOrderDetails c ON ps.s_name = c.c_name
WHERE 
    ps.part_rank <= 3
GROUP BY 
    ps.s_name, p.part_count, p.avg_price, c.c_name, c.total_revenue, c.total_items
ORDER BY 
    c.total_revenue DESC;
