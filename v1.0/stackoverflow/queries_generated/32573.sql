WITH RecursiveUserPostStats AS (
    -- Recursive CTE to accumulate statistics on users based on their posts
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COUNT(DISTINCT COALESCE(c.Id, 0)) AS TotalComments
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
    
    UNION ALL

    SELECT 
        u.Id,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COUNT(DISTINCT COALESCE(c.Id, 0)) AS TotalComments
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE u.Id IN (SELECT UserId FROM RecursiveUserPostStats)
    GROUP BY u.Id, u.DisplayName
),
PostVoteStats AS (
    -- CTE for aggregate voting statistics on the posts
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE -1 END) AS Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE -1 END) DESC) AS Rank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId 
    GROUP BY p.Id
),
UserBadges AS (
    -- CTE to get user badges counts
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(up.Questions, 0) AS TotalQuestions,
    COALESCE(up.Answers, 0) AS TotalAnswers,
    COALESCE(up.TotalComments, 0) AS TotalComments,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    MAX(vs.UpVotes) AS MostUpvotedPostUpVotes,
    MAX(vs.DownVotes) AS MostDownvotedPostDownVotes,
    MAX(vs.Score) AS MostScoredPostScore,
    COUNT(DISTINCT p.Id) AS TotalPosts
FROM Users u
LEFT JOIN RecursiveUserPostStats up ON u.Id = up.UserId
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN PostVoteStats vs ON vs.PostId = p.Id
GROUP BY u.Id, u.DisplayName, u.Reputation
ORDER BY u.Reputation DESC, TotalQuestions DESC, TotalAnswers DESC;
