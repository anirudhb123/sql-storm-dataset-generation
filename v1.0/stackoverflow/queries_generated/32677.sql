WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        AcceptedAnswerId,
        ParentId,
        CreationDate,
        Score,
        1 AS HierarchyLevel
    FROM Posts
    WHERE PostTypeId = 1  -- Selecting Questions only
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.AcceptedAnswerId,
        p.ParentId,
        p.CreationDate,
        p.Score,
        ph.HierarchyLevel + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy ph ON p.ParentId = ph.Id
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(ps.UpVotes, 0) - COALESCE(ps.DownVotes, 0) AS NetScore,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ps.UpVotes, 0) DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    LEFT JOIN PostVoteStats ps ON p.Id = ps.PostId
    WHERE p.PostTypeId = 1  -- Questions only
)
SELECT 
    ph.Title AS QuestionTitle,
    ph.CreationDate AS QuestionDate,
    ph.Score AS QuestionScore,
    ps.UpVotes,
    ps.DownVotes,
    ub.TotalBadges,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE((
        SELECT COUNT(*)
        FROM Posts ans
        WHERE ans.ParentId = ph.Id AND ans.PostTypeId = 2
    ), 0) AS TotalAnswers,
    ROW_NUMBER() OVER (ORDER BY ph.Score DESC) AS PostRank
FROM RecursivePostHierarchy ph
INNER JOIN PostVoteStats ps ON ph.Id = ps.PostId
INNER JOIN Users u ON u.Id = ph.OwnerUserId
INNER JOIN UserBadgeStats ub ON ub.UserId = u.Id
WHERE ph.HierarchyLevel = 1 -- Include only root questions
  AND ps.UpVotes > 0  -- Only include questions with upvotes
  AND ph.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for posts from the last year
ORDER BY postRank
OPTION (MAXRECURSION 100);
