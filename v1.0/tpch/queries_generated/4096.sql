WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_price
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        s.s_suppkey, s.s_name
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(l.l_linenumber) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    COALESCE(lds.total_value, 0) AS total_lineitem_value,
    s.s_name AS supplier_name,
    s.total_available,
    s.total_supply_cost,
    r.region AS order_status_description
FROM 
    RankedOrders o
LEFT JOIN 
    LineItemDetails lds ON o.o_orderkey = lds.l_orderkey
JOIN 
    supplier s ON o.o_orderkey = s.s_suppkey
LEFT JOIN 
    region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = s.s_nationkey)
WHERE 
    o.rank_price <= 5
  AND 
    o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
ORDER BY 
    o.o_orderdate DESC, total_lineitem_value DESC;
