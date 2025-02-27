
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        COALESCE(a.Id, -1) AS AcceptedAnswerId,
        COALESCE(a.Body, '') AS AcceptedAnswerBody,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN 
        (SELECT 
             PostId, 
             COUNT(*) AS CommentCount 
         FROM 
             Comments 
         GROUP BY 
             PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
),
TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        FilteredPosts f
    JOIN 
        (SELECT a.N + 1 AS n FROM (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) a) n 
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5
),
PostEngagement AS (
    SELECT 
        fp.PostId,
        fp.Title,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounty,
        fp.ViewCount,
        fp.Score,
        ts.PostCount
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Comments c ON fp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON fp.PostId = v.PostId AND v.VoteTypeId IN (2, 3) 
    LEFT JOIN 
        TagStatistics ts ON FIND_IN_SET(ts.TagName, REPLACE(REPLACE(fp.Tags, '><', ','), '<', '')) > 0
    GROUP BY 
        fp.PostId, fp.Title, fp.ViewCount, fp.Score, ts.PostCount
)
SELECT 
    pe.PostId,
    pe.Title,
    pe.TotalComments,
    pe.TotalBounty,
    pe.ViewCount,
    pe.Score,
    pe.PostCount,
    ROUND((100.0 * pe.TotalComments / NULLIF(pe.ViewCount, 0)), 2) AS CommentRatio,
    ROUND((100.0 * pe.Score / NULLIF(pe.ViewCount, 0)), 2) AS ScoreRatio
FROM 
    PostEngagement pe
ORDER BY 
    pe.Score DESC, pe.TotalComments DESC
LIMIT 50;
