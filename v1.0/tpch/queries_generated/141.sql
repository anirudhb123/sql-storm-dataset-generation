WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2021-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        Count(DISTINCT ps.ps_partkey) AS total_parts,
        Sum(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_availqty) AS avg_available_quantity
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COALESCE(ps.total_supply_cost, 0) AS total_supply_cost,
        (CASE 
            WHEN p.p_retailprice > 100 THEN 'Expensive'
            WHEN p.p_retailprice BETWEEN 50 AND 100 THEN 'Moderate'
            ELSE 'Cheap'
        END) AS price_category
    FROM 
        part p
    LEFT JOIN 
        SupplierStats ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    lst.l_orderkey,
    COUNT(DISTINCT ps.s_suppkey) AS unique_suppliers_count,
    AVG(ld.l_discount) AS average_discount,
    SUM(ld.l_extendedprice * (1 - ld.l_discount)) AS total_revenue,
    pd.price_category,
    SUM(pd.total_supply_cost) AS aggregate_supply_cost
FROM 
    lineitem lst
JOIN 
    PartDetails pd ON lst.l_partkey = pd.p_partkey
JOIN 
    supplier s ON lst.l_suppkey = s.s_suppkey
LEFT JOIN 
    RankedOrders ro ON lst.l_orderkey = ro.o_orderkey
WHERE 
    lst.l_shipdate >= DATE '2021-01-01'
    AND (lst.l_returnflag = 'N' OR lst.l_returnflag IS NULL)
    AND (ro.rn <= 10 OR ro.rn IS NULL)
GROUP BY 
    lst.l_orderkey, pd.price_category
HAVING 
    SUM(ld.l_extendedprice * (1 - ld.l_discount)) > 1000
ORDER BY 
    total_revenue DESC;
