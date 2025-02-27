
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > DATEADD(YEAR, -1, '2024-10-01 12:34:56') 
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score <= 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(p.Score * 1.0) AS AverageScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' + '<' + t.TagName + '>%'
    GROUP BY 
        t.TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        AVG(u.Reputation * 1.0) AS AverageReputation
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.Score AS PostScore,
    rp.ViewCount,
    rp.CreationDate,
    ts.TagName,
    ts.TotalPosts,
    ts.PositivePosts,
    ts.NegativePosts,
    ts.AverageScore,
    ur.DisplayName AS Author,
    ur.TotalPosts AS AuthorTotalPosts,
    ur.UpvotedPosts AS AuthorUpvotedPosts,
    ur.AverageReputation
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON ts.TagName IN (SELECT value FROM STRING_SPLIT(rp.Tags, '> <')) 
JOIN 
    UserReputation ur ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
WHERE 
    rp.Rank <= 10 
ORDER BY 
    ts.AverageScore DESC, 
    rp.ViewCount DESC;
