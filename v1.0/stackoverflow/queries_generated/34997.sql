WITH RecursivePostHierarchy AS (
    -- Recursive CTE to find all answers related to questions and their respective user details
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        1 AS Level,
        p.CreationDate
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Select Questions
    
    UNION ALL
    
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.OwnerUserId,
        r.Level + 1,
        a.CreationDate
    FROM Posts a
    INNER JOIN RecursivePostHierarchy r ON a.ParentId = r.PostId
    WHERE a.PostTypeId = 2 -- Select Answers
),
PostVoteCounts AS (
    -- CTE to count votes for questions and answers
    SELECT 
        p.Id,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
UserBadges AS (
    -- Aggregate user badges for additional details
    SELECT
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)

SELECT 
    r.PostId AS PostId,
    r.Title AS PostTitle,
    u.DisplayName AS Author,
    COALESCE(b.GoldBadges, 0) AS GoldBadges,
    COALESCE(b.SilverBadges, 0) AS SilverBadges,
    COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
    pvc.UpVotes,
    pvc.DownVotes,
    r.Level AS PostLevel,
    r.CreationDate,
    CASE 
        WHEN r.Level = 1 THEN 'Question'
        ELSE 'Answer'
    END AS PostType,
    DENSE_RANK() OVER (PARTITION BY r.OwnerUserId ORDER BY r.CreationDate DESC) AS RecentActivityRank
FROM RecursivePostHierarchy r
JOIN Users u ON r.OwnerUserId = u.Id
LEFT JOIN UserBadges b ON u.Id = b.UserId
LEFT JOIN PostVoteCounts pvc ON r.PostId = pvc.Id
ORDER BY r.CreationDate DESC, r.Level;

-- This query uses common table expressions (CTEs) to build up several layers of information 
-- and correlate data regarding posts, votes by users, and badge achievements, while also 
-- classifying posts into “Question” or “Answer” categories based on hierarchy.
