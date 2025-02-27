WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        COALESCE(SUM(o.o_totalprice - (l.l_discount * o.o_totalprice)), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2021-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COALESCE(SUM(o.o_totalprice), 0) > 5000
),
TopProducts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        total_revenue DESC
    LIMIT 10
)
SELECT 
    ns.n_name AS supplier_nation,
    hvc.c_name AS customer_name,
    tp.p_name AS top_product,
    ns.total_supplycost,
    hvc.total_spent,
    CASE 
        WHEN ns.rank = 1 THEN 'Top Supplier'
        ELSE 'Supplier'
    END AS supplier_rank_status
FROM 
    RankedSuppliers ns
JOIN 
    HighValueCustomers hvc ON ns.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM TopProducts tp WHERE tp.p_partkey = ps.ps_partkey) LIMIT 1)
JOIN 
    TopProducts tp ON tp.total_revenue = (
        SELECT MAX(total_revenue) FROM TopProducts
    )
WHERE 
    ns.total_supplycost > 10000
ORDER BY 
    hvc.total_spent DESC NULLS LAST
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
