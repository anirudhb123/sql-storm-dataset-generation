WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),

SuppliersCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),

CustomerNation AS (
    SELECT 
        c.c_custkey,
        c.c_nationkey,
        n.n_name AS nation_name,
        c.c_acctbal
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal > 1000
),

PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        COALESCE(SU.total_supply_cost, 0) AS supply_cost
    FROM 
        part p
    LEFT JOIN 
        SuppliersCost SU ON p.p_partkey = SU.ps_partkey
)

SELECT 
    CN.nation_name,
    PD.p_name,
    COUNT(DISTINCT LO.l_orderkey) AS number_of_orders,
    SUM(LO.l_extendedprice * (1 - LO.l_discount)) AS total_sales,
    AVG(LO.l_tax) AS average_tax,
    MAX(PO.o_totalprice) AS max_order_price
FROM 
    lineitem LO
JOIN 
    RankedOrders PO ON LO.l_orderkey = PO.o_orderkey
JOIN 
    PartDetails PD ON LO.l_partkey = PD.p_partkey
JOIN 
    CustomerNation CN ON PO.o_custkey = CN.c_custkey
WHERE 
    LO.l_shipdate <= CURRENT_DATE
    AND (LO.l_returnflag = 'N' OR LO.l_returnflag IS NULL)
GROUP BY 
    CN.nation_name,
    PD.p_name
HAVING 
    SUM(LO.l_extendedprice) > 50000
ORDER BY 
    total_sales DESC, 
    number_of_orders ASC;
