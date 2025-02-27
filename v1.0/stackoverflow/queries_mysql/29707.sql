
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY TRIM(BOTH '><' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5  
),
PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  
    GROUP BY 
        p.Id
),
FinalResults AS (
    SELECT 
        trp.Title,
        trp.OwnerDisplayName,
        trp.CreationDate,
        trp.ViewCount,
        trp.Score,
        trp.Tags,
        pvc.VoteCount
    FROM 
        TopRankedPosts trp
    JOIN 
        PostVoteCounts pvc ON trp.PostId = pvc.PostId
)
SELECT 
    Title,
    OwnerDisplayName,
    CreationDate,
    ViewCount,
    Score,
    Tags,
    VoteCount,
    CONCAT('Popular Tag: ', (SELECT DISTINCT TRIM(BOTH '><' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(TR.Tags, '><', numbers.n), '><', -1)) FROM FinalResults TR WHERE TR.Tags IS NOT NULL LIMIT 1)) AS PopularTag
FROM 
    FinalResults
ORDER BY 
    VoteCount DESC, 
    Score DESC
LIMIT 10;
