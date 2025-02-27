WITH SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.n_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        CONCAT(s.s_name, ' located at ', s.s_address, ' with phone ', s.s_phone) AS full_details
    FROM
        supplier s
),
PartDetails AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        CONCAT(p.p_name, ' of size ', p.p_size, ' in container ', p.p_container, ' costs ', p.p_retailprice) AS part_summary
    FROM
        part p
),
CustomerDetails AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.n_nationkey,
        c.c_phone,
        c.c_acctbal,
        c.c_mktsegment,
        CONCAT(c.c_name, ' living at ', c.c_address, ' with market segment ', c.c_mktsegment) AS customer_profile
    FROM
        customer c
),
OrderDetails AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        o.o_clerk,
        CONCAT('Order ', o.o_orderkey, ' for Customer ', o.o_custkey, ' on ', o.o_orderdate, ' with total price of ', o.o_totalprice) AS order_info
    FROM
        orders o
)
SELECT
    pd.part_summary,
    sd.full_details,
    cd.customer_profile,
    od.order_info
FROM
    PartDetails pd
JOIN
    lineitem l ON pd.p_partkey = l.l_partkey
JOIN
    OrderDetails od ON l.l_orderkey = od.o_orderkey
JOIN
    SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
JOIN
    CustomerDetails cd ON od.o_custkey = cd.c_custkey
WHERE
    sd.s_acctbal > 1000
    AND od.o_orderstatus = 'O'
ORDER BY
    od.o_totalprice DESC
LIMIT 100;
