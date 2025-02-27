WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS num_parts,
        DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY COUNT(ps.ps_partkey) DESC) AS rnk
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
    HAVING 
        COUNT(ps.ps_partkey) > 0
),
NationalStats AS (
    SELECT 
        n.n_nationkey, 
        n.n_name,
        SUM(COALESCE(s.s_acctbal, 0)) AS total_acctbal,
        COUNT(DISTINCT c.c_custkey) AS cust_count,
        SUM(o.o_totalprice) AS total_orders
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus NOT IN ('F', 'O')
),
UniquePartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(MAX(CASE WHEN ps.ps_availqty > 0 THEN p.p_container END), 'OUT OF STOCK') AS available_container,
        AVG(l.l_discount) AS avg_discount
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    ns.n_name,
    COUNT(DISTINCT cs.c_custkey) AS unique_customers,
    SUM(CASE WHEN cs.order_rank <= 3 THEN cs.o_totalprice ELSE 0 END) AS total_top_orders,
    STRING_AGG(DISTINCT up.available_container || ' (' || up.avg_discount || ')') AS part_info
FROM 
    NationalStats ns
LEFT JOIN 
    CustomerOrders cs ON ns.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = cs.c_custkey)
LEFT JOIN 
    UniquePartInfo up ON cs.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = cs.c_custkey))
GROUP BY 
    ns.n_name
HAVING 
    COUNT(DISTINCT cs.c_custkey) > 10 AND
    SUM(CASE WHEN cs.order_rank <= 3 THEN cs.o_totalprice ELSE 0 END) > 10000
ORDER BY 
    unique_customers DESC;
