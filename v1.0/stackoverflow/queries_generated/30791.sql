WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 -- Only questions
),
PostDetails AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        CASE 
            WHEN rp.ViewCount IS NULL THEN 0
            ELSE rp.ViewCount 
        END AS AdjustedViewCount,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        UNNEST(string_to_array(rp.Tags, ',')) AS tag ON TRUE -- Separate tags
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(tag)
    WHERE
        rp.rn <= 5 -- We only want the last 5 posts per user
    GROUP BY
        rp.PostId, rp.Title, rp.ViewCount, rp.Score
),
PostHistorySummary AS (
    SELECT
        p.Id AS PostId,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY
        p.Id
),
PopularPosts AS (
    SELECT
        pd.PostId,
        pd.Title,
        pd.ViewCount,
        pd.Score,
        pd.AdjustedViewCount,
        pd.CommentCount,
        pH.HistoryCount,
        pH.LastEdited
    FROM
        PostDetails pd
    JOIN 
        PostHistorySummary pH ON pd.PostId = pH.PostId
    WHERE
        pd.Score > 10 AND pd.CommentCount > 5 -- Filtering for popular questions
)
SELECT
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.Score,
    pp.AdjustedViewCount,
    pp.CommentCount,
    pp.HistoryCount,
    pp.LastEdited
FROM
    PopularPosts pp
ORDER BY
    pp.ViewCount DESC
LIMIT 20;

-- Explanation:
-- 1. RankedPosts CTE ranks posts by creation date within each user.
-- 2. PostDetails aggregates data for the last 5 questions posted by each user, including comment count and tags.
-- 3. PostHistorySummary counts post history events and finds the last edit date for each post.
-- 4. PopularPosts filters the combined results for posts with over 10 score and more than 5 comments.
