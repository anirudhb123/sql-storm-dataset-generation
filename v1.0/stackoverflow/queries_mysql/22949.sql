
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        p.OwnerUserId,
        u.Reputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR 
        AND p.PostTypeId IN (1, 2) 
),
DistinctTags AS (
    SELECT
        DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1)) AS TagName,
        p.Id AS PostId
    FROM 
        Posts p
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= n.n - 1
    WHERE 
        p.Tags IS NOT NULL
),
PostScores AS (
    SELECT 
        rp.PostId,
        COALESCE(v.TotalVotes, 0) AS TotalVotes,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        rp.Reputation,
        (rp.Score + COALESCE(v.TotalVotes, 0) + COALESCE(b.BadgeCount, 0)) AS TotalScore
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS TotalVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON rp.PostId = v.PostId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON rp.OwnerUserId = b.UserId
)
SELECT 
    pt.TagName,
    COUNT(ps.PostId) AS PostsCount,
    AVG(ps.TotalScore) AS AverageScore
FROM 
    DistinctTags dt
JOIN 
    PostScores ps ON dt.PostId = ps.PostId
JOIN 
    Tags pt ON pt.TagName = dt.TagName
GROUP BY 
    pt.TagName
HAVING 
    AVG(ps.TotalScore) > (
        SELECT 
            AVG(TotalScore)
        FROM 
            PostScores
    ) * 0.75 
ORDER BY 
    AverageScore DESC
LIMIT 10;
