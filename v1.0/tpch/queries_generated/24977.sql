WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders AS o
    WHERE 
        o.o_orderdate >= '2022-01-01' 
        AND o.o_orderdate <= CURRENT_DATE
),
SupplierPartCosts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp AS ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
MaxCosts AS (
    SELECT 
        p.p_partkey,
        MAX(spc.total_supply_cost) AS max_cost
    FROM 
        part AS p
    JOIN 
        SupplierPartCosts AS spc ON p.p_partkey = spc.ps_partkey
    GROUP BY 
        p.p_partkey
),
OrderLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_discount,
        l.l_extendedprice
    FROM 
        lineitem AS l
    WHERE 
        l.l_returnflag = 'N' 
        AND l.l_shipdate BETWEEN '2022-06-01' AND '2022-12-31'
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(oli.l_extendedprice * (1 - oli.l_discount)) AS net_revenue
    FROM 
        RankedOrders AS o
    LEFT JOIN 
        OrderLineItems AS oli ON o.o_orderkey = oli.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice
)
SELECT 
    f.o_orderkey,
    f.o_totalprice,
    f.net_revenue,
    (SELECT COUNT(DISTINCT s.s_suppkey) 
     FROM supplier AS s 
     WHERE s.s_acctbal IS NOT NULL AND s.s_nationkey IN (SELECT n.n_nationkey 
                                                             FROM nation AS n 
                                                             WHERE n.n_regionkey = (SELECT r.r_regionkey 
                                                                                     FROM region AS r 
                                                                                     WHERE r.r_name LIKE '%North%'))
    ) AS supplier_count,
    CASE 
        WHEN f.net_revenue > 0 THEN 'Profitable'
        ELSE 'Unprofitable'
    END AS profitability_status
FROM 
    FilteredOrders AS f
JOIN 
    MaxCosts AS mc ON f.o_orderkey IN (SELECT li.l_orderkey 
                                         FROM lineitem AS li 
                                         WHERE li.l_partkey IN (SELECT mp.p_partkey 
                                                                FROM part AS mp 
                                                                WHERE mp.p_mfgr IN ('Manufacturer#1', 'Manufacturer#2')))
WHERE 
    f.o_totalprice IS NOT NULL
ORDER BY 
    f.o_totalprice DESC
FETCH FIRST 10 ROWS ONLY;
