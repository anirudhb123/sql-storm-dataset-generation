WITH PostTagCounts AS (
    SELECT
        p.Id AS PostId,
        COUNT(t.Id) AS TagCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM
        Posts p
    JOIN
        Tags t ON t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')))
    WHERE
        p.PostTypeId = 1  -- Focus on Questions
    GROUP BY
        p.Id
),
PostScoreData AS (
    SELECT
        p.Id AS PostId,
        p.Score,
        p.CreationDate,
        COALESCE(ph.UserDisplayName, 'N/A') AS LastEditor,
        p.LastEditDate,
        pt.Name AS PostType
    FROM
        Posts p
    LEFT JOIN
        PostHistory ph ON p.LastEditorUserId = ph.UserId
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE
        p.Score > 0  -- Filter for posts with positive scores
),
RankedPosts AS (
    SELECT
        ps.PostId,
        ps.Score,
        ps.CreationDate,
        ps.LastEditor,
        ps.LastEditDate,
        ps.PostType,
        ROW_NUMBER() OVER (ORDER BY ps.Score DESC) AS Rank,
        pct.TagCount,
        pct.Tags
    FROM
        PostScoreData ps
    JOIN
        PostTagCounts pct ON ps.PostId = pct.PostId
    WHERE
        pct.TagCount >= 5  -- Only consider posts with 5 or more tags
)
SELECT
    r.Rank,
    r.PostId,
    r.Score,
    r.CreationDate,
    r.LastEditor,
    r.LastEditDate,
    r.PostType,
    r.TagCount,
    r.Tags
FROM
    RankedPosts r
WHERE
    r.Rank <= 10  -- Get top 10 posts
ORDER BY
    r.Rank;
