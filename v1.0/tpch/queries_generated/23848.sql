WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice IS NOT NULL 
        AND o.o_orderdate >= DATE '2023-01-01'
), 

SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 

CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_mktsegment,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_mktsegment
), 

FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown Size' 
            ELSE CAST(p.p_size AS varchar)
        END AS size_desc
    FROM 
        part p
    WHERE 
        p.p_retailprice < 500 
        OR p.p_comment LIKE '%economy%'
)

SELECT 
    r.r_name,
    COUNT(DISTINCT fd.c_custkey) AS total_customers,
    SUM(fd.total_spent) AS revenue,
    AVG(fd.order_count) AS average_orders,
    SC.total_cost AS supplier_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    CustomerDetails fd ON c.c_custkey = fd.c_custkey
LEFT JOIN 
    FilteredParts p ON EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey AND l.l_orderkey IN (
            SELECT o.o_orderkey 
            FROM RankedOrders ro 
            WHERE ro.o_orderstatus = 'F'
        )
    )
LEFT JOIN 
    SupplierCosts SC ON SC.ps_partkey = p.p_partkey
WHERE 
    fd.total_spent IS NOT NULL 
    AND r.r_name IS NOT NULL
GROUP BY 
    r.r_name, SC.total_cost
HAVING 
    COUNT(DISTINCT fd.c_custkey) > 10 
ORDER BY 
    revenue DESC NULLS LAST;
