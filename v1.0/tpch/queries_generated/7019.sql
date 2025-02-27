WITH SupplierAggregate AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerNationAggregate AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, n.n_name
),
PartRevenue AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '2022-01-01' AND l.l_shipdate < '2023-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    cn.nation_name,
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    SUM(cs.total_order_value) AS total_sales,
    SUM(pa.total_revenue) AS total_part_revenue,
    COUNT(DISTINCT sa.s_suppkey) AS supplier_count,
    SUM(sa.total_supply_cost) AS total_cost
FROM 
    CustomerNationAggregate cs
JOIN 
    nation cn ON cs.nation_name = cn.n_name
JOIN 
    SupplierAggregate sa ON cn.n_nationkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = cn.n_nationkey)
JOIN 
    PartRevenue pa ON pa.total_revenue > 0
GROUP BY 
    cn.nation_name
ORDER BY 
    total_sales DESC, customer_count DESC;
