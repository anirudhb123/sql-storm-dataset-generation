
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierAggregates AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        c.c_acctbal,
        DENSE_RANK() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal IS NOT NULL
),
LineItemDiscounts AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_discounted_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate > DATE '1998-10-01' - INTERVAL '6 months'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    COALESCE(cd.c_name, 'Unknown Customer') AS customer_name,
    COALESCE(cd.nation_name, 'Unknown Region') AS region_name,
    ro.o_orderkey,
    ro.o_orderstatus,
    ro.o_totalprice,
    ro.rank,
    sa.total_supply_cost,
    lid.total_discounted_price,
    CASE 
        WHEN ro.o_totalprice > 1000 THEN 'High Value'
        ELSE 'Standard Value' 
    END AS order_value_category
FROM 
    RankedOrders ro
LEFT JOIN 
    CustomerDetails cd ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cd.c_custkey)
LEFT JOIN 
    SupplierAggregates sa ON sa.ps_suppkey = ANY(SELECT ps.ps_suppkey FROM partsupp ps JOIN lineitem l ON l.l_partkey = ps.ps_partkey WHERE l.l_orderkey = ro.o_orderkey)
LEFT JOIN 
    LineItemDiscounts lid ON lid.l_orderkey = ro.o_orderkey
WHERE 
    ro.rank <= 10
ORDER BY 
    ro.o_orderstatus, ro.o_totalprice DESC;
