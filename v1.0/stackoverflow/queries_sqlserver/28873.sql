
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
        p.CreationDate >= CAST(DATEADD(year, -1, '2024-10-01') AS DATE)
        AND p.PostTypeId = 1 
),
TagSummary AS (
    SELECT
        value AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    CROSS APPLY STRING_SPLIT(TRIM(BOTH '<>' FROM Tags), '><')
    WHERE
        Tags IS NOT NULL
    GROUP BY
        value
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
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
    TagSummary ts ON ts.TagName IN (SELECT value FROM STRING_SPLIT(TRIM(BOTH '<>' FROM rp.Tags), '><'))
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
