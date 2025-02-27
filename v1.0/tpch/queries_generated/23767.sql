WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as status_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' AND 
        o.o_orderdate < '2024-01-01'
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        CASE 
            WHEN l.l_returnflag = 'R' THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM 
        lineitem l
)
SELECT 
    n.n_name AS nation,
    r.r_name AS region,
    SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS revenue,
    COUNT(DISTINCT oo.o_orderkey) AS orders_count,
    COUNT(DISTINCT pp.p_partkey) AS distinct_parts,
    COALESCE(MAX(su.total_supply_cost), 0) AS max_supplier_cost,
    STRING_AGG(DISTINCT ol.return_status, ', ') AS return_status_summary
FROM 
    RankedOrders oo
JOIN 
    OrderLineItems ol ON oo.o_orderkey = ol.l_orderkey
JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = oo.o_custkey)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT OUTER JOIN 
    SupplierPartDetails su ON ol.l_partkey = su.p_partkey
LEFT JOIN 
    part pp ON ol.l_partkey = pp.p_partkey
WHERE 
    oo.status_rank <= 10 AND 
    (n.n_name LIKE 'A%' OR n.n_name LIKE 'B%')
GROUP BY 
    n.n_name, r.r_name
HAVING 
    revenue > 10000 OR MAX(su.total_supply_cost) IS NULL
ORDER BY 
    revenue DESC, orders_count ASC;
