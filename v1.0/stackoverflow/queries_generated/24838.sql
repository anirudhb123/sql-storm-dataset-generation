WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        CASE 
            WHEN Reputation >= 1000 THEN 'High'
            WHEN Reputation BETWEEN 500 AND 999 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM Users
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPosts,
        AVG(DATEDIFF('minute', p.CreationDate, COALESCE(p.LastActivityDate, NOW()))) AS AvgActivityDelay
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    GROUP BY p.Id, p.OwnerUserId
),
QualifiedPosts AS (
    SELECT 
        ps.PostId,
        ps.OwnerUserId,
        u.ReputationCategory,
        ps.Upvotes,
        ps.Downvotes,
        ps.CommentCount,
        ps.RelatedPosts,
        ps.AvgActivityDelay,
        ROW_NUMBER() OVER (PARTITION BY u.ReputationCategory ORDER BY ps.Upvotes DESC, ps.CommentCount DESC) AS RankWithinCategory
    FROM PostStatistics ps
    JOIN UserReputation u ON ps.OwnerUserId = u.UserId
    WHERE ps.AvgActivityDelay < 60 -- Considering only posts with activity delay less than 60 minutes
)

SELECT 
    qp.PostId,
    qp.Upvotes,
    qp.Downvotes,
    qp.CommentCount,
    qp.RelatedPosts,
    u.DisplayName,
    CASE 
        WHEN qp.RankWithinCategory = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostLabel,
    CASE 
        WHEN qp.CommentCount > 10 THEN 'Highly Discussed'
        WHEN qp.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Discussed'
        ELSE 'Less Discussed'
    END AS DiscussionLevel,
    COALESCE(NULLIF(qp.ReputationCategory, 'Low'), 'No Reputation') AS EffectiveReputationCategory
FROM QualifiedPosts qp
JOIN Users u ON qp.OwnerUserId = u.Id
WHERE qp.RankWithinCategory <= 5 -- Top 5 posts in each category
ORDER BY u.ReputationCategory, qp.Upvotes DESC;

WITH TotalVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(*) AS VoteCount
    FROM Votes
    GROUP BY PostId
)
SELECT 
    p.Title,
    tv.TotalUpvotes,
    tv.TotalDownvotes,
    tv.VoteCount,
    (tv.TotalUpvotes - tv.TotalDownvotes) AS NetScore,
    COALESCE(CAST(p.Body AS VARCHAR(1000)), 'No body available') AS BodyPreview,
    CASE 
        WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM Posts p
JOIN TotalVotes tv ON p.Id = tv.PostId
WHERE (tv.TotalUpvotes - tv.TotalDownvotes) > 5
ORDER BY NetScore DESC;

SELECT 
    DISTINCT ON (p.Id) 
    p.Id AS PostId,
    p.Title,
    t.TagName,
    ph.UserDisplayName,
    ph.Comment AS ChangeComment,
    ph.CreationDate AS ChangeDate,
    CASE 
        WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closure Action'
        WHEN ph.PostHistoryTypeId IN (24) THEN 'Edit Action'
        ELSE 'Miscellaneous'
    END AS ActionType
FROM PostHistory ph
JOIN Posts p ON ph.PostId = p.Id
LEFT JOIN Tags t ON p.Tags LIKE '%' || t.TagName || '%' -- Match any tags
WHERE ph.UserId IS NOT NULL
  AND (ph.PostHistoryTypeId IN (10, 11, 24) OR ph.Comment IS NOT NULL)
ORDER BY p.Id, ph.CreationDate DESC;
