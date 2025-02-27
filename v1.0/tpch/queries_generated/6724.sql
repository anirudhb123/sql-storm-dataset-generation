WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER(PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.o_orderstatus
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 10
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalReport AS (
    SELECT 
        to.o_orderkey,
        to.o_orderdate,
        to.o_totalprice,
        to.o_orderstatus,
        ss.s_name AS supplier_name,
        cs.c_name AS customer_name,
        cs.total_orders,
        cs.total_spent,
        ss.total_supply_cost
    FROM 
        TopOrders to
    JOIN 
        lineitem li ON li.l_orderkey = to.o_orderkey
    JOIN 
        partsupp ps ON li.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        CustomerStats cs ON to.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
    JOIN 
        SupplierDetails ss ON ss.s_suppkey = s.s_suppkey
)
SELECT 
    fr.o_orderkey,
    fr.o_orderdate,
    fr.o_totalprice,
    fr.o_orderstatus,
    fr.supplier_name,
    fr.customer_name,
    fr.total_orders,
    fr.total_spent,
    fr.total_supply_cost
FROM 
    FinalReport fr
ORDER BY 
    fr.o_totalprice DESC;
