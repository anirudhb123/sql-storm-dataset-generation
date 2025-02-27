WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
TopCustomers AS (
    SELECT 
        r.r_name AS region, 
        n.n_name AS nation, 
        oc.c_name AS customer_name, 
        SUM(o.o_totalprice) AS total_spend
    FROM 
        RankedOrders ro
    JOIN 
        customer oc ON ro.o_orderkey = oc.c_custkey
    JOIN 
        nation n ON oc.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.OrderRank <= 10
    GROUP BY 
        r.r_name, n.n_name, oc.c_name
),
SupplierDetails AS (
    SELECT 
        s.s_name AS supplier_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
)
SELECT 
    tc.region,
    tc.nation,
    tc.customer_name,
    tc.total_spend,
    sd.supplier_name,
    sd.total_supply_cost
FROM 
    TopCustomers tc
JOIN 
    SupplierDetails sd ON tc.region = (SELECT DISTINCT r_name FROM region WHERE r_regionkey IN (SELECT DISTINCT n_regionkey FROM nation WHERE n_nationkey IN (SELECT DISTINCT c_nationkey FROM customer WHERE c_name = tc.customer_name)))
ORDER BY 
    tc.total_spend DESC, sd.total_supply_cost ASC;
