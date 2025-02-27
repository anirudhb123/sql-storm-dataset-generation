WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_quantity) AS total_quantity,
        ROW_NUMBER() OVER (ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    p.p_name,
    ns.region_name,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    AVG(rs.s_acctbal) AS avg_supplier_acctbal,
    SUM(os.total_revenue) AS total_order_revenue,
    SUM(os.total_quantity) AS total_order_quantity
FROM 
    part p
JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.s_suppkey
JOIN 
    OrderSummary os ON os.o_orderkey IN (
        SELECT DISTINCT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey
    )
JOIN 
    NationRegion ns ON ns.n_nationkey = (
        SELECT c.c_nationkey 
        FROM customer c 
        JOIN orders o ON c.c_custkey = o.o_custkey 
        WHERE o.o_orderkey = os.o_orderkey
        LIMIT 1
    )
GROUP BY 
    p.p_name, ns.region_name
HAVING 
    AVG(rs.s_acctbal) IS NOT NULL 
ORDER BY 
    total_order_revenue DESC, p.p_name;
