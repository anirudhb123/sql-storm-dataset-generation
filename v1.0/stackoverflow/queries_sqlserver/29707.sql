
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY TRIM(REPLACE(REPLACE(p.Tags, '><', ' '), ' ', '')) ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
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
    'Popular Tag: ' + (SELECT TOP 1 tag FROM STRING_SPLIT(TRIM(REPLACE(REPLACE(Tags, '><', ' '), ' ', '')), ' ') WHERE tag <> '' ORDER BY NEWID()) AS PopularTag
FROM 
    FinalResults
ORDER BY 
    VoteCount DESC, 
    Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
