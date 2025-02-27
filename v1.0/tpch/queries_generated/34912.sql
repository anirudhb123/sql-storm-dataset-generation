WITH RECURSIVE SalesCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.r_name AS region_name,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'No Balance' 
            ELSE 'Balance Available' 
        END AS balance_status
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(p.p_retailprice) AS avg_price
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS line_item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000.00
)
SELECT 
    c.c_name AS customer_name,
    s.s_name AS supplier_name,
    pd.p_name AS part_name,
    COALESCE(o.o_totalprice, 0) AS order_total,
    COALESCE(SUM(o.o_totalprice), 0) AS total_spent,
    pd.total_available,
    si.region_name,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY total_spent DESC) AS customer_rank
FROM 
    SalesCTE c
LEFT JOIN 
    HighValueOrders o ON c.c_custkey = o.o_orderkey
JOIN 
    SupplierInfo si ON si.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE '%SomePart%') LIMIT 1)
JOIN 
    PartDetails pd ON pd.p_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE '%SomePart%')
GROUP BY 
    c.c_custkey, c.c_name, s.s_name, pd.p_name, o.o_totalprice, pd.total_available, si.region_name
ORDER BY 
    customer_rank, total_spent DESC;
