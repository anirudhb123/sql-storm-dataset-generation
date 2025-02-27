WITH UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.Score >= 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScoreCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
FilteredBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserDetails AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.QuestionCount,
        ups.AnswerCount,
        ups.PositiveScoreCount,
        ups.NegativeScoreCount,
        ISNULL(b.GoldBadges, 0) AS GoldBadges,
        ISNULL(b.SilverBadges, 0) AS SilverBadges,
        ISNULL(b.BronzeBadges, 0) AS BronzeBadges
    FROM 
        UserPostStatistics ups
    LEFT JOIN 
        FilteredBadges b ON ups.UserId = b.UserId
)
SELECT 
    ud.DisplayName,
    ud.TotalPosts,
    ud.QuestionCount,
    ud.AnswerCount,
    ud.PositiveScoreCount,
    ud.NegativeScoreCount,
    ud.GoldBadges,
    ud.SilverBadges,
    ud.BronzeBadges,
    CASE 
        WHEN ud.GoldBadges + ud.SilverBadges + ud.BronzeBadges > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus,
    CASE 
        WHEN ud.TotalPosts IS NULL OR ud.TotalPosts = 0 THEN 'No Activity'
        WHEN ud.AnswerCount > 0 AND ud.QuestionCount > 0 THEN 'Active Contributor'
        ELSE 'Lurker'
    END AS UserActivityStatus
FROM 
    UserDetails ud
WHERE 
    ud.TotalPosts > 10
ORDER BY 
    ud.TotalPosts DESC, ud.DisplayName ASC;

WITH RecentVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        v.VoteTypeId,
        ROW_NUMBER() OVER (PARTITION BY v.PostId ORDER BY v.CreationDate DESC) AS RecentVoteRank
    FROM 
        Votes v
)
SELECT 
    p.Title,
    p.OwnerDisplayName,
    COALESCE(rv.UserId, -1) AS LastVotingUserId,
    CASE 
        WHEN rv.VoteTypeId IN (2, 5) THEN 'Liked'
        WHEN rv.VoteTypeId = 3 THEN 'Disliked'
        ELSE 'No Vote'
    END AS LastVote,
    p.Score,
    COUNT(DISTINCT c.Id) AS CommentCount,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId = 10) AS CloseVotes
FROM 
    Posts p
LEFT JOIN 
    RecentVotes rv ON p.Id = rv.PostId AND rv.RecentVoteRank = 1
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate > NOW() - INTERVAL '30 days'
GROUP BY 
    p.Id, p.Title, p.OwnerDisplayName, rv.UserId, rv.VoteTypeId, p.Score
HAVING 
    COUNT(DISTINCT c.Id) > 0
ORDER BY 
    p.Score DESC, p.Title;

WITH RecursiveCTE AS (
    SELECT 
        p.Id,
        p.Title,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        r.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursiveCTE r ON r.Id = p.ParentId
    WHERE 
        p.PostTypeId = 2 -- Answers
)
SELECT 
    r.Id
