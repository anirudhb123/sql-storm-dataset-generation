WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice
    FROM 
        RankedOrders ro
    WHERE 
        ro.OrderRank <= 10
),
SupplierDetails AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        ps.ps_supplycost,
        p.p_name,
        p.p_brand
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerCounts AS (
    SELECT 
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        o.o_orderkey
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.o_totalprice,
    COUNT(sd.s_name) AS supplier_count,
    cc.customer_count,
    STRING_AGG(CONCAT(sd.s_name, ' (', sd.s_acctbal, ')'), ', ') AS suppliers_detail
FROM 
    TopOrders to
LEFT JOIN 
    SupplierDetails sd ON sd.p_name IN (SELECT p.p_name FROM part p INNER JOIN lineitem li ON p.p_partkey = li.l_partkey WHERE li.l_orderkey = to.o_orderkey)
LEFT JOIN 
    CustomerCounts cc ON cc.o_orderkey = to.o_orderkey
GROUP BY 
    to.o_orderkey, to.o_orderdate, to.o_totalprice
ORDER BY 
    to.o_totalprice DESC;
