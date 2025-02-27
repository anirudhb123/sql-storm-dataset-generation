
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS Author,
        u.Reputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND  
        p.CreationDate >= NOW() - INTERVAL 6 MONTH
),

TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS TagFrequency
    FROM 
        RankedPosts
    JOIN 
        (SELECT a.N FROM (SELECT 1 AS N UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) a) n
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.N - 1
    GROUP BY 
        TagName
),

FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.Reputation,
        rp.ViewCount,
        rp.Score,
        tc.TagName,
        tc.TagFrequency
    FROM 
        RankedPosts rp
    JOIN 
        TagCounts tc ON rp.Tags LIKE CONCAT('%', tc.TagName, '%')  
    WHERE 
        rp.Rank <= 5  
)

SELECT 
    fr.PostId,
    fr.Title,
    fr.Author,
    fr.Reputation,
    fr.ViewCount,
    fr.Score,
    fr.TagName,
    fr.TagFrequency
FROM 
    FinalResults fr
ORDER BY 
    fr.Reputation DESC, 
    fr.Score DESC;
