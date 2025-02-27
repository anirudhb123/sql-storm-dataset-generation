
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
        @row_number := IF(@prev_tag = t.TagName, @row_number + 1, 1) AS TagRank,
        @prev_tag := t.TagName,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpvoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
        WHERE 
            CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) t
    JOIN (SELECT @row_number := 0, @prev_tag := '') AS vars
    WHERE 
        p.PostTypeId = 1 AND
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
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
     LIMIT 1) th ON th.Tags = ps.TagName
ORDER BY 
    ps.PostCount DESC;
