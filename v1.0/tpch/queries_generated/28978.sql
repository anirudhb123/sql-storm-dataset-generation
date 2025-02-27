WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
), 
PartSuppliers AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name, 
        rp.p_brand, 
        ps.ps_supplycost, 
        s.s_name AS supplier_name, 
        s.s_nationkey, 
        ROW_NUMBER() OVER (PARTITION BY rp.p_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM RankedParts rp
    JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE rp.price_rank <= 3
), 
NationInfo AS (
    SELECT 
        n.n_name, 
        n.n_nationkey, 
        COUNT(DISTINCT ps.s_suppkey) AS supplier_count
    FROM PartSuppliers ps
    JOIN nation n ON ps.s_nationkey = n.n_nationkey
    GROUP BY n.n_name, n.n_nationkey
), 
AggregateData AS (
    SELECT 
        pi.p_brand, 
        ni.n_name AS nation_name, 
        SUM(pi.ps_supplycost) AS total_supply_cost, 
        COUNT(DISTINCT pi.supplier_name) AS total_suppliers
    FROM PartSuppliers pi
    JOIN NationInfo ni ON pi.n_nationkey = ni.n_nationkey
    GROUP BY pi.p_brand, ni.n_name
)
SELECT 
    p_brand, 
    nation_name, 
    total_supply_cost, 
    total_suppliers 
FROM AggregateData 
ORDER BY total_supply_cost DESC, nation_name;
