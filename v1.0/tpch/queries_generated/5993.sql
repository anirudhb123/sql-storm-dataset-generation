WITH SupplyCostAnalysis AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name
),
OrderAnalysis AS (
    SELECT 
        l.l_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_partkey) AS item_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        l.l_orderkey, o.o_orderstatus
),
CustomerOverview AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    SUM(sa.total_supply_cost) AS total_supply_cost,
    SUM(oa.total_order_value) AS total_order_value,
    SUM(co.total_spent) AS total_customer_spent
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplyCostAnalysis sa ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey IN (SELECT p_partkey FROM part)))
LEFT JOIN 
    OrderAnalysis oa ON oa.l_orderkey IN (SELECT l_orderkey FROM lineitem)
LEFT JOIN 
    CustomerOverview co ON co.c_custkey IN (SELECT o_custkey FROM orders)
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    total_supply_cost DESC, total_order_value DESC, total_customer_spent DESC;
