WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.ViewCount DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1 -- Considering only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts from the last year
),
FilteredPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount
    FROM
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 3 -- Top 3 posts by score in each tag
        AND rp.RecentPostRank = 1 -- Most recent post by owner
),
TagStatistics AS (
    SELECT
        UNNEST(string_to_array(STRING_AGG(DISTINCT Tags, ','), ',')) AS Tag,
        COUNT(*) AS TotalPosts,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM
        FilteredPosts
    GROUP BY
        Tag
)
SELECT
    ts.Tag,
    ts.TotalPosts,
    ts.TotalViews,
    ts.TotalScore,
    ROUND(ts.TotalScore::numeric / NULLIF(ts.TotalPosts, 0), 2) AS AverageScorePerPost,
    STRING_AGG(fp.LayoutTitle, '; ') AS RecentPostTitles
FROM
    TagStatistics ts
LEFT JOIN
    FilteredPosts fp ON ts.Tag = ANY(string_to_array(fp.Tags, ','))
GROUP BY
    ts.Tag, ts.TotalPosts, ts.TotalViews, ts.TotalScore
ORDER BY
    ts.TotalViews DESC;
