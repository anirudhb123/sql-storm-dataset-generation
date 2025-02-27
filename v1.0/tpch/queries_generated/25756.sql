WITH String_Processing AS (
    SELECT
        p.p_partkey,
        SUBSTRING(p.p_name, 1, 10) AS short_name,
        LOWER(p.p_comment) AS lower_comment,
        UPPER(p.p_mfgr) AS upper_mfgr,
        CONCAT('Part ', p.p_partkey, ': ', p.p_name) AS formatted_name,
        LENGTH(p.p_container) AS container_length,
        REPLACE(p.p_comment, 'obsolete', 'deprecated') AS updated_comment
    FROM
        part p
),
Nation_Suppliers AS (
    SELECT
        n.n_name,
        s.s_name,
        CONCAT(n.n_name, ' Supplier: ', s.s_name) AS nation_supplier_info,
        LENGTH(s.s_address) AS address_length
    FROM
        nation n
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
),
Orders_Aggregated AS (
    SELECT
        o.o_orderkey,
        COUNT(l.l_orderkey) AS total_lineitems,
        SUM(l.l_extendedprice) AS total_extended_price,
        MAX(o.o_orderdate) AS latest_order_date
    FROM
        orders o
    LEFT JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey
)
SELECT
    sp.short_name,
    sp.lower_comment,
    ns.nation_supplier_info,
    oa.total_lineitems,
    oa.total_extended_price,
    oa.latest_order_date,
    CASE
        WHEN oa.total_extended_price > 10000 THEN 'High Value'
        ELSE 'Normal Value'
    END AS order_value_category
FROM
    String_Processing sp
JOIN
    Nation_Suppliers ns ON ns.nation_supplier_info LIKE CONCAT('%', sp.short_name, '%')
JOIN
    Orders_Aggregated oa ON oa.o_orderkey IN (
        SELECT o.o_orderkey FROM orders o WHERE o.o_orderkey = sp.p_partkey
    )
ORDER BY 
    sp.short_name, ns.n_name;
