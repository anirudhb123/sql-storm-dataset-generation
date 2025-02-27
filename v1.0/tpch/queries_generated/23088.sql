WITH CTE_SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_acctbal - (SELECT COALESCE(SUM(l.l_extendedprice * l.l_discount), 0) 
                        FROM lineitem l 
                        WHERE l.l_suppkey = s.s_suppkey AND l.l_returnflag = 'R') AS net_balance,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_in_nation
    FROM 
        supplier s
), 
CTE_CustomerDetails AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
CTE_PartAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CTE_CrossJoin AS (
    SELECT 
        c.c_name AS customer_name, 
        s.s_name AS supplier_name,
        pd.p_name AS part_name,
        pd.p_retailprice AS retail_price,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Unknown Supplier'
            WHEN sd.net_balance > 0 THEN 'Positive Balance'
            ELSE 'Negative Balance'
        END AS balance_status
    FROM 
        CTE_CustomerDetails c 
    LEFT JOIN 
        CTE_SupplierDetails sd ON sd.rank_in_nation = 1
    CROSS JOIN 
        part pd
)
SELECT 
    cj.customer_name,
    cj.supplier_name,
    cj.part_name,
    cj.retail_price,
    COALESCE(av.total_available, 0) AS available_quantity,
    cj.balance_status,
    CASE 
        WHEN cj.retail_price > (SELECT AVG(p2.p_retailprice) FROM part p2) THEN 'Above Average Price'
        ELSE 'Below Average Price'
    END AS price_comparison
FROM 
    CTE_CrossJoin cj
LEFT JOIN 
    CTE_PartAvailability av ON av.ps_partkey = (SELECT MAX(ps.ps_partkey) FROM partsupp ps WHERE ps.ps_suppkey = cj.supplier_name)
WHERE 
    cj.balance_status != 'Unknown Supplier'
ORDER BY 
    cj.customer_name, 
    cj.retail_price DESC
LIMIT 50 OFFSET 100;
