WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT pp.p_size FROM part pp WHERE pp.p_retailprice < 50.00)
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supplier_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
    HAVING 
        SUM(ps.ps_availqty) > (SELECT AVG(ps2.ps_availqty) FROM partsupp ps2 WHERE ps2.ps_partkey = ps.ps_partkey)
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(DISTINCT li.l_linenumber) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_totalprice > 1000.00 AND o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        total_spent IS NOT NULL AND total_spent > (SELECT AVG(total_spent) FROM (SELECT SUM(o2.o_totalprice) AS total_spent FROM customer c2 LEFT JOIN orders o2 ON c2.c_custkey = o2.o_custkey GROUP BY c2.c_custkey) AS avg_spent)
),
FinalResults AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_retailprice,
        cu.c_name,
        coalesce(cus.order_count, 0) AS total_orders,
        coalesce(cus.total_spent, 0.00) AS customer_spending,
        sc.total_supplier_cost
    FROM 
        RankedParts rp
    LEFT JOIN 
        SupplierCosts sc ON rp.p_partkey = sc.ps_partkey
    LEFT JOIN 
        HighValueOrders co ON rp.p_partkey IN (SELECT li.l_partkey FROM lineitem li WHERE li.l_orderkey = co.o_orderkey)
    LEFT JOIN 
        CustomerOrderSummary cus ON co.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cus.c_custkey)
)
SELECT 
    fr.p_partkey,
    fr.p_name,
    fr.p_retailprice,
    fr.c_name,
    fr.total_orders,
    fr.customer_spending,
    fr.total_supplier_cost
FROM 
    FinalResults fr
WHERE 
    fr.customer_spending IS NOT NULL
ORDER BY 
    fr.p_retailprice DESC NULLS LAST, 
    fr.total_orders DESC, 
    fr.customer_spending ASC;
