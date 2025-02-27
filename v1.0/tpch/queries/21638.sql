
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 500
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        AVG(o.o_totalprice) > (
            SELECT AVG(o2.o_totalprice)
            FROM orders o2
            WHERE o2.o_orderdate BETWEEN '1995-01-01' AND '1998-10-01'
        )
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    WHERE 
        l.l_discount > 0.05 AND l.l_shipdate <= '1998-10-01'
    GROUP BY 
        l.l_orderkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(hl.total_value, 0) AS order_total,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY COALESCE(hl.total_value, 0) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        HighValueCustomers hvc ON c.c_custkey = hvc.c_custkey
    LEFT JOIN 
        region r ON c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
    LEFT JOIN 
        FilteredLineItems hl ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = hl.l_orderkey LIMIT 1)
)
SELECT 
    cd.c_custkey,
    cd.c_name,
    cd.order_total,
    cd.region_name,
    ss.s_name AS top_supplier
FROM 
    CustomerOrderDetails cd
LEFT JOIN 
    RankedSuppliers ss ON cd.order_rank = 1
WHERE 
    cd.order_total > 10000 AND 
    (cd.region_name IS NULL OR cd.region_name LIKE 'N%')
ORDER BY 
    cd.order_total DESC;
