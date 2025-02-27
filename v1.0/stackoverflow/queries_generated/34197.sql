WITH RecursivePostHierarchy AS (
    SELECT Id, Title, ParentId, CreationDate, Score, 1 AS Level
    FROM Posts
    WHERE ParentId IS NULL -- Base case: top-level questions

    UNION ALL

    SELECT p.Id, p.Title, p.ParentId, p.CreationDate, p.Score, ph.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy ph ON p.ParentId = ph.Id -- Recursive case: find children posts
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS QuestionCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
RecentPostActivity AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS RelatedPostCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN RecursivePostHierarchy rph ON p.Id = rph.Id OR p.ParentId = rph.Id
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount
),
AggregatedStatistics AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        ra.ViewCount,
        ra.CommentCount,
        us.QuestionCount,
        (us.UpVotes - us.DownVotes) AS NetVoteScore,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges
    FROM Posts p
    JOIN RecentPostActivity ra ON p.Id = ra.Id
    JOIN UserStatistics us ON p.OwnerUserId = us.UserId
)
SELECT
    'Overview of Top Questions' AS ReportTitle,
    COUNT(*) AS TotalTopQuestions,
    AVG(NetVoteScore) AS AverageNetVoteScore,
    SUM(GoldBadges) AS TotalGoldBadges
FROM AggregatedStatistics
WHERE CreationDate >= CURRENT_DATE - INTERVAL '30 days' -- Filter for recent questions
HAVING AVG(NetVoteScore) >= 10 -- Only include questions with a positive net vote score
ORDER BY TotalTopQuestions DESC;

-- Compute rank using a window function
WITH RankedPosts AS (
    SELECT 
        Id,
        Title,
        CreationDate,
        ViewCount,
        CommentCount,
        ROW_NUMBER() OVER (ORDER BY ViewCount DESC) AS Rank
    FROM AggregatedStatistics
)
SELECT 
    Rank,
    Title,
    ViewCount,
    CommentCount
FROM RankedPosts
WHERE Rank <= 10; -- Top 10 questions by view count

