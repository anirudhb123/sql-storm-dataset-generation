WITH RecursiveTagTree AS (
    SELECT 
        Id,
        TagName,
        Count,
        ExcerptPostId,
        WikiPostId,
        IsModeratorOnly,
        IsRequired,
        1 AS Level
    FROM Tags
    WHERE IsModeratorOnly = 0  -- Starting point for tags
    UNION ALL
    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        t.ExcerptPostId,
        t.WikiPostId,
        t.IsModeratorOnly,
        t.IsRequired,
        rt.Level + 1
    FROM Tags t
    INNER JOIN RecursiveTagTree rt ON rt.Id = t.WikiPostId
),
VoteSummary AS (
    SELECT
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY PostId
),
LatestPosts AS (
    SELECT 
        p.*,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 YEAR'  -- Only last year's posts
),
PostCloseReasons AS (
    SELECT
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY ph.PostId
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    lp.Title,
    lp.Score,
    COALESCE(vs.Upvotes, 0) AS Upvotes,
    COALESCE(vs.Downvotes, 0) AS Downvotes,
    ppt.CloseReasons,
    rt.TagName,
    rt.Level,
    lp.CreationDate,
    lp.LastActivityDate
FROM LatestPosts lp
JOIN Users u ON lp.OwnerUserId = u.Id
LEFT JOIN VoteSummary vs ON lp.Id = vs.PostId
LEFT JOIN PostCloseReasons ppt ON lp.Id = ppt.PostId
LEFT JOIN RecursiveTagTree rt ON rt.Id = lp.Tags::int  -- ensuring Tags used as int for JOIN
WHERE lp.Score > 10  -- Filter for popular posts
  AND (ppt.LastClosedDate IS NULL OR ppt.LastClosedDate < lp.LastActivityDate)  -- Only active posts
ORDER BY lp.LastActivityDate DESC
LIMIT 100;
