WITH SupplierPartCost AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_sold,
        AVG(l.l_extendedprice) AS avg_price,
        MAX(l.l_discount) AS max_discount
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    spc.s_name AS supplier_name,
    cs.c_name AS customer_name,
    cs.total_orders,
    cs.total_spent,
    ps.p_name AS part_name,
    ps.avg_price,
    ps.total_sold,
    ps.max_discount,
    spc.total_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    SupplierPartCost spc ON spc.s_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = n.n_nationkey)
JOIN 
    CustomerOrderDetails cs ON cs.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
JOIN 
    PartSummary ps ON ps.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = spc.s_suppkey)
ORDER BY 
    r.r_name, n.n_name, spc.total_cost DESC;
