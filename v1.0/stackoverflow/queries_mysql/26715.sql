
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
        TRIM(BOTH '>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN 
        (SELECT a.N + b.N * 10 + 1 n FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) numbers
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
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
        CreationDate >= NOW() - INTERVAL 30 DAY
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
    TagStats ts ON FIND_IN_SET(ts.Tag, TRIM(BOTH '>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '><', numbers.n), '><', -1)))
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
WHERE 
    rp.Rank = 1 
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;
