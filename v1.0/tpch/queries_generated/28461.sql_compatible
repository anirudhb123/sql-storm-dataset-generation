
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUBSTRING(p.p_name FROM 1 FOR 10) AS short_name,
        LENGTH(p.p_name) AS name_length,
        CONCAT('Part: ', p.p_name, ' | Type: ', p.p_type) AS description,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
), SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        CONCAT(s.s_name, ' - ', s.s_address) AS supplier_detail,
        ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), OrdersWithQuantities AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        o.o_orderdate,
        o.o_orderpriority,
        o.o_comment,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_quantity) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderpriority, o.o_comment
)
SELECT 
    rp.short_name,
    rp.description,
    si.nation_name,
    si.supplier_detail,
    ow.total_quantity,
    ow.o_orderdate,
    ow.o_orderpriority,
    CONCAT('Order ', ow.o_orderkey, ' has a total quantity of ', ow.total_quantity) AS order_summary
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
JOIN 
    OrdersWithQuantities ow ON ow.o_orderkey = ps.ps_partkey
WHERE 
    rp.rank <= 5 AND si.supplier_rank <= 10 AND ow.order_rank <= 15
ORDER BY 
    rp.p_partkey, si.s_suppkey, ow.total_quantity DESC;
