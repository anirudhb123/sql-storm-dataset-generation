WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        p.p_partkey,
        rp.price_rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN RankedParts rp ON ps.ps_partkey = rp.p_partkey
)
SELECT 
    sd.s_name AS Supplier_Name,
    sd.nation AS Supplier_Nation,
    GROUP_CONCAT(CONCAT(sd.p_partkey, ': ', rp.p_name, ' (Rank: ', rp.price_rank, ')') SEPARATOR ', ') AS Products,
    SUM(sd.s_acctbal) AS Total_Account_Balance
FROM SupplierDetails sd
JOIN RankedParts rp ON sd.p_partkey = rp.p_partkey
WHERE rp.price_rank <= 3
GROUP BY sd.s_name, sd.nation
ORDER BY Total_Account_Balance DESC;
