WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
), RankedUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM UserStats
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalPosts,
    Questions,
    Answers,
    Wikis,
    TotalComments,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    UpVotes,
    DownVotes,
    ReputationRank,
    PostRank
FROM RankedUsers
WHERE ReputationRank <= 50 OR PostRank <= 50
ORDER BY ReputationRank, PostRank;
