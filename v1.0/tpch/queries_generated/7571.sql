WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 100000
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(l.l_quantity) AS total_quantity_sold,
        AVG(l.l_discount) AS avg_discount,
        SUM(l.l_extendedprice) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    nsr.n_name AS nation_name,
    r.region_name,
    COUNT(DISTINCT hvc.c_custkey) AS high_value_customers_count,
    SUM(p.total_quantity_sold) AS total_part_sales,
    SUM(rsv.total_supply_value) AS total_supply_value
FROM 
    RankedSuppliers rsv
JOIN 
    nation nsr ON rsv.s_nationkey = nsr.n_nationkey
JOIN 
    region r ON nsr.n_regionkey = r.r_regionkey
LEFT JOIN 
    HighValueCustomers hvc ON rsv.s_nationkey = hvc.c_nationkey
LEFT JOIN 
    PartDetails p ON rsv.s_suppkey = p.l_orderkey
GROUP BY 
    nsr.n_name, r.region_name
ORDER BY 
    total_part_sales DESC, nation_name;
