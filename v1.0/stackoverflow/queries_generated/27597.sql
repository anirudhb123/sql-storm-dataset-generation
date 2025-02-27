WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE
        p.PostTypeId = 1 -- Only questions
    GROUP BY
        p.Id, u.DisplayName
),
EnhancedPostStats AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount,
        CASE
            WHEN rp.Score >= 10 THEN 'High Score'
            WHEN rp.Score BETWEEN 1 AND 9 THEN 'Moderate Score'
            ELSE 'Low Score'
        END AS ScoreCategory,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM
        RankedPosts rp
    LEFT JOIN Posts p ON rp.PostId = p.Id
    LEFT JOIN LATERAL (
        SELECT 
            TRIM(UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')))::varchar) AS TagName
    ) AS t ON true
    GROUP BY
        rp.PostId, rp.Title, rp.Body, rp.Tags, rp.CreationDate, rp.Score, rp.ViewCount, rp.OwnerDisplayName, rp.CommentCount, rp.VoteCount
)
SELECT
    eps.PostId,
    eps.Title,
    eps.Body,
    eps.CreationDate,
    eps.Score,
    eps.ViewCount,
    eps.OwnerDisplayName,
    eps.CommentCount,
    eps.VoteCount,
    eps.ScoreCategory,
    eps.TagList,
    CASE 
        WHEN eps.CommentCount < 5 AND eps.Score < 5 THEN 'Low Engagement'
        WHEN eps.CommentCount >= 5 AND eps.Score >= 10 THEN 'High Engagement'
        ELSE 'Moderate Engagement'
    END AS EngagementLevel
FROM
    EnhancedPostStats eps
WHERE
    eps.TagList ILIKE '%sql%' OR eps.TagList ILIKE '%database%'
ORDER BY
    eps.ViewCount DESC, eps.Score DESC
LIMIT 100;
