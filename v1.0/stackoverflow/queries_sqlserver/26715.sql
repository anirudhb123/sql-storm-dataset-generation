
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),

TagStats AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE 
        PostTypeId = 1
    GROUP BY 
        value
    HAVING 
        COUNT(*) > 10 
),

RecentVotes AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    WHERE 
        CreationDate >= DATEADD(DAY, -30, GETDATE())
    GROUP BY 
        PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    ts.Tag,
    ts.TagCount,
    rv.UpVotes,
    rv.DownVotes
FROM 
    RankedPosts rp
JOIN 
    TagStats ts ON ts.Tag IN (SELECT value FROM STRING_SPLIT(SUBSTRING(rp.Tags, 2, LEN(rp.Tags) - 2), '><'))
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
WHERE 
    rp.Rank = 1 
ORDER BY 
    rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
