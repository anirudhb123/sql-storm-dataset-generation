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
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.PostTypeId = 1 -- Only Questions
),
TagSummary AS (
    SELECT
        unnest(string_to_array(Trim(Both '<>' FROM Tags), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
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
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    WHERE 
        p.PostTypeId = 1 -- Only Questions
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
    TagSummary ts ON ts.TagName = ANY (string_to_array(Trim(Both '<>' FROM rp.Tags), '><')) -- Tags present in both Rank and Summary
LEFT JOIN
    HighScorePosts hs ON hs.Id = rp.PostId
LEFT JOIN
    CommentStatistics cs ON cs.PostId = rp.PostId
WHERE
    rp.RankByViews <= 5 -- Get top 5 most viewed posts per owner
ORDER BY
    rp.OwnerDisplayName,
    rp.ViewCount DESC, 
    ts.PostCount DESC NULLS LAST;
