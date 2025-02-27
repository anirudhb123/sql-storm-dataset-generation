WITH RECURSIVE PriceSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        MIN(ps.ps_supplycost) AS min_supply_cost,
        MAX(ps.ps_supplycost) AS max_supply_cost,
        COUNT(*) AS supp_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
NationRegion AS (
    SELECT 
        n.n_name AS nation,
        r.r_name AS region,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name, r.r_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        MAX(o.o_orderdate) AS latest_order_date,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    p.p_name,
    p.total_supply_cost,
    nr.supplier_count,
    os.total_price,
    os.latest_order_date,
    CASE 
        WHEN os.price_rank = 1 THEN 'Top Price'
        ELSE 'Regular Price'
    END AS price_status,
    COALESCE(p.max_supply_cost / NULLIF(p.min_supply_cost, 0), -1) AS cost_ratio
FROM 
    PriceSummary p
LEFT OUTER JOIN 
    NationRegion nr ON CHAR_LENGTH(p.p_name) < 15 -- bizarre length requirement
JOIN 
    OrderStats os ON os.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE '%Acme%' LIMIT 1)
WHERE 
    (p.total_supply_cost > 1000 OR nr.supplier_count IS NULL)
    AND p.p_mfgr NOT IN ('Manufacturer1', 'Manufacturer2') -- exclusion of certain manufacturers
ORDER BY 
    cost_ratio DESC NULLS LAST;
