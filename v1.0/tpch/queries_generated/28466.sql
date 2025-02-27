WITH PartDetails AS (
    SELECT 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_retailprice,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_available_qty,
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_name, p.p_brand, p.p_type, p.p_size, p.p_retailprice
),
SupplierDetails AS (
    SELECT 
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        SUBSTRING(s.s_comment, 1, 20) AS brief_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
CustomerDetails AS (
    SELECT 
        c.c_name,
        c.c_mktsegment,
        LENGTH(c.c_address) AS address_length
    FROM 
        customer c
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
)
SELECT 
    pd.p_name,
    pd.p_brand,
    pd.p_type,
    pd.p_size,
    pd.p_retailprice,
    pd.total_available_qty,
    pd.total_supply_cost,
    sd.s_name,
    sd.nation_name,
    sd.s_acctbal,
    sd.brief_comment,
    cd.c_name AS customer_name,
    cd.c_mktsegment,
    cd.address_length,
    od.o_orderdate,
    od.lineitem_count
FROM 
    PartDetails pd
JOIN 
    SupplierDetails sd ON pd.total_available_qty > 0
JOIN 
    CustomerDetails cd ON LENGTH(cd.c_name) > 5
JOIN 
    OrderDetails od ON od.lineitem_count > 1
ORDER BY 
    pd.p_retailprice DESC, 
    sd.s_acctbal ASC, 
    cd.address_length DESC;
