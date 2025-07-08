
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
        TRIM(REGEXP_SUBSTR(TAG, '([^><]+)', 1, seq)) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts,
        LATERAL FLATTEN(input => SPLIT(SUBSTR(Tags, 2, LENGTH(Tags) - 2), '><')) AS TAG
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
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
        CreationDate >= CURRENT_TIMESTAMP() - INTERVAL '30 day'
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
    TagStats ts ON ts.Tag IN (SELECT TRIM(REGEXP_SUBSTR(substring(rp.Tags, 2, LENGTH(rp.Tags) - 2), '([^><]+)', 1, seq)) FROM TABLE(GENERATOR(ROWCOUNT => 1000)) seq)
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
WHERE 
    rp.Rank = 1 
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;
