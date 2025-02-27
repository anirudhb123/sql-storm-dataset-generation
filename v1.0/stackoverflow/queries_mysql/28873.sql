
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR)
        AND p.PostTypeId = 1 
),
TagSummary AS (
    SELECT
        TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1)) AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    JOIN 
        (SELECT @row := @row + 1 AS n FROM 
           (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) AS a,
           (SELECT @row := 0) AS b) n
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
),
HighScorePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.Tags,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.Tags
    HAVING 
        SUM(v.BountyAmount) > 0 
    ORDER BY 
        TotalBounty DESC
LIMIT 10
),
CommentStatistics AS (
    SELECT
        PostId,
        COUNT(*) AS TotalComments,
        MAX(CreationDate) AS LastCommentDate
    FROM
        Comments
    GROUP BY
        PostId
)
SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerDisplayName,
    ts.TagName,
    hs.Score,
    hs.TotalBounty,
    cs.TotalComments,
    cs.LastCommentDate
FROM
    RankedPosts rp
LEFT JOIN
    TagSummary ts ON ts.TagName IN (TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '><', n.n), '><', -1)))
LEFT JOIN
    HighScorePosts hs ON hs.Id = rp.PostId
LEFT JOIN
    CommentStatistics cs ON cs.PostId = rp.PostId
WHERE
    rp.RankByViews <= 5 
ORDER BY
    rp.OwnerDisplayName,
    rp.ViewCount DESC, 
    ts.PostCount DESC;
