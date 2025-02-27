WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND 
        o.o_orderdate < DATE '2023-01-01'
), 
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), 
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COALESCE(SUM(l.l_discount), 0) AS total_discount,
        COUNT(l.l_orderkey) AS total_orders
    FROM 
        part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(o.o_totalprice) AS total_order_value,
    AVG(pd.total_discount) AS avg_discount_per_part,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    Customer c ON s.s_suppkey = c.c_nationkey
JOIN 
    RankedOrders o ON c.c_custkey = o.o_orderkey
JOIN 
    PartDetails pd ON pd.p_partkey IN (SELECT ps.p_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
WHERE 
    o.order_rank <= 10
GROUP BY 
    r.r_name
ORDER BY 
    total_order_value DESC
LIMIT 5;
