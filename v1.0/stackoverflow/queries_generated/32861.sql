WITH RecursivePostHierarchy AS (
    -- CTE to get the hierarchy of posts (Questions and their answers)
    SELECT
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Start from Questions
    UNION ALL
    SELECT
        p2.Id AS PostId,
        p2.ParentId,
        p2.Title,
        p2.CreationDate,
        Level + 1
    FROM Posts p2
    INNER JOIN RecursivePostHierarchy rph ON p2.ParentId = rph.PostId
    WHERE p2.PostTypeId = 2 -- Only Answers
),
PostActivity AS (
    -- Get recent post edits and their types along with user activity
    SELECT
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS ActivityDate,
        u.DisplayName AS UserDisplayName,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closure'
            WHEN ph.PostHistoryTypeId IN (24, 25) THEN 'Edit'
            ELSE 'Other'
        END AS ActivityType
    FROM PostHistory ph
    LEFT JOIN Users u ON ph.UserId = u.Id
    WHERE ph.CreationDate >= NOW() - INTERVAL '30 days' -- 30 days window
),
ScoreRankings AS (
    -- Assign rankings to posts based on score and view count
    SELECT
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        RANK() OVER(ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Only Questions
),
UserBadges AS (
    -- Get user badges and their details
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        b.Name AS BadgeName,
        b.Class
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
),
PostTags AS (
    -- Get the tags associated with each question
    SELECT
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    INNER JOIN Tags t ON p.Tags LIKE '%' || t.TagName || '%' -- Check tag inclusion
    WHERE p.PostTypeId = 1  -- Only Questions
    GROUP BY p.Id
)
SELECT
    rph.PostId AS QuestionId,
    rph.Title AS QuestionTitle,
    ScoreRankings.Rank,
    PostTags.Tags,
    COALESCE(json_agg(distinct ub.BadgeName) FILTER (WHERE ub.BadgeName IS NOT NULL), '[]') AS UserBadges,
    COUNT(DISTINCT pa.PostId) AS RecentActivityCount,
    MAX(pa.ActivityDate) AS LastActivityDate
FROM RecursivePostHierarchy rph
JOIN ScoreRankings ON rph.PostId = ScoreRankings.Id
JOIN PostTags ON rph.PostId = PostTags.PostId
LEFT JOIN UserBadges ub ON rph.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ub.UserId)
LEFT JOIN PostActivity pa ON rph.PostId = pa.PostId
GROUP BY rph.PostId, rph.Title, ScoreRankings.Rank, PostTags.Tags
ORDER BY ScoreRankings.Rank
FETCH FIRST 10 ROWS ONLY; -- Limit output to the top 10 ranked questions
