
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT t.TagName) AS TagCount,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM Posts p
         INNER JOIN (
             SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
         ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS t ON TRUE
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title
),
PostScores AS (
    SELECT 
        p.Id,
        p.Score,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(ph.Comment, '') AS LastEditComment
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
        AND ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = p.Id) 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Score, ph.Comment
),
RankedPosts AS (
    SELECT 
        pt.PostId,
        pt.Title,
        pt.TagCount,
        pt.TagsList,
        ps.Score,
        ps.TotalBounty,
        ps.LastEditComment,
        @rank := @rank + 1 AS Rank
    FROM 
        PostTagCounts pt
    JOIN 
        PostScores ps ON pt.PostId = ps.Id,
        (SELECT @rank := 0) r
    ORDER BY 
        pt.TagCount DESC, ps.Score DESC
)
SELECT 
    r.Rank,
    r.Title,
    r.TagCount,
    r.TagsList,
    r.Score,
    r.TotalBounty,
    r.LastEditComment
FROM 
    RankedPosts r
WHERE 
    r.TagCount > 0
ORDER BY 
    r.Rank;
