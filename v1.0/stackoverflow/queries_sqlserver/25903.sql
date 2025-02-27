
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        t.TagName,
        RANK() OVER (PARTITION BY t.TagName ORDER BY p.ViewCount DESC) AS TagRank,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpvoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS APPLY 
        (SELECT value AS TagName FROM STRING_SPLIT(p.Tags, '><')) AS t
    WHERE 
        p.PostTypeId = 1 AND
        p.CreationDate >= cast('2024-10-01 12:34:56' as datetime) - INTERVAL '1 year'
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName,
        TagName,
        TagRank,
        UpvoteCount
    FROM 
        RankedPosts
    WHERE 
        TagRank = 1
),
PostStatistics AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount,
        AVG(Score) AS AvgScore,
        AVG(ViewCount) AS AvgViewCount,
        SUM(UpvoteCount) AS TotalUpvotes
    FROM 
        TopRankedPosts
    GROUP BY 
        TagName
)
SELECT 
    ps.TagName,
    ps.PostCount,
    ps.AvgScore,
    ps.AvgViewCount,
    ps.TotalUpvotes,
    th.CreatedBy AS TopContributor
FROM 
    PostStatistics ps
JOIN 
    (SELECT 
         p.Tags,
         u.DisplayName AS CreatedBy
     FROM 
         Posts p
     JOIN 
         Users u ON p.OwnerUserId = u.Id
     WHERE 
         p.PostTypeId = 1 
     GROUP BY 
         p.Tags, u.DisplayName 
     ORDER BY 
         COUNT(*) DESC 
     OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY) th ON th.Tags = ps.TagName
ORDER BY 
    ps.PostCount DESC;
