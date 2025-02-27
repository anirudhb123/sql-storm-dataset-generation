WITH RankedProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > 0
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
Suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal
    FROM 
        supplier s
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        AVG(line.l_discount) AS average_discount
    FROM 
        RankedProducts p
    JOIN 
        lineitem line ON p.p_partkey = line.l_partkey
    WHERE 
        p.price_rank <= 5  -- Top 5 expensive products by type
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    c.c_custkey,
    c.total_spent,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(tp.average_discount, 0) AS average_discount,
    r.r_name AS region_name
FROM 
    CustomerOrders c
LEFT JOIN 
    Suppliers s ON s.s_acctbal = (SELECT MAX(s2.s_acctbal) FROM Suppliers s2 WHERE s2.s_acctbal < c.total_spent)
LEFT JOIN 
    region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = s.s_nationkey LIMIT 1)
LEFT JOIN 
    TopProducts tp ON tp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
WHERE 
    c.order_count > 1
    AND (c.total_spent - COALESCE(tp.average_discount, 0) > 1000 OR tp.average_discount IS NULL)
ORDER BY 
    c.total_spent DESC;
