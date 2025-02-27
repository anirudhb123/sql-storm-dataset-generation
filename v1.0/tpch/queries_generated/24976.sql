WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
HighValueOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATEADD(month, -12, GETDATE())
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 10000
),
ProductSupplies AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        pp.ps_availqty,
        ps.ps_supplycost,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS supply_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        RankedSuppliers pp ON ps.ps_suppkey = pp.s_suppkey AND pp.supplier_rank = 1
),
FilteredProducts AS (
    SELECT 
        *,
        CASE 
            WHEN p_retailprice IS NULL THEN 'Unknown Price'
            WHEN p_retailprice < 50 THEN 'Low Value'
            WHEN p_retailprice BETWEEN 50 AND 200 THEN 'Medium Value'
            ELSE 'High Value'
        END AS value_category
    FROM 
        ProductSupplies
    WHERE 
        ps_availqty > 0
    AND 
        ps_supplycost IS NOT NULL
)
SELECT 
    fp.p_name,
    fp.value_category,
    SUM(CASE WHEN lo.l_returnflag = 'R' THEN lo.l_extendedprice ELSE 0 END) AS total_returned_value,
    AVG(lo.l_discount) AS average_discount,
    COUNT(DISTINCT ho.c_custkey) AS high_value_customers
FROM 
    FilteredProducts fp
LEFT JOIN 
    lineitem lo ON fp.p_partkey = lo.l_partkey
LEFT JOIN 
    HighValueOrders ho ON lo.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = ho.c_custkey)
WHERE 
    fp.supply_rank = 1
GROUP BY 
    fp.p_name, 
    fp.value_category
ORDER BY 
    total_returned_value DESC NULLS LAST, 
    average_discount DESC NULLS FIRST;
