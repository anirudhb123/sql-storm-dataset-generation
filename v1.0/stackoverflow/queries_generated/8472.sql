WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        SUM(v.VoteTypeId = 5) AS Favorites,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId 
    LEFT JOIN Votes v ON p.Id = v.PostId 
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        Upvotes,
        Downvotes,
        Favorites,
        Questions,
        Answers,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY Upvotes DESC) AS VoteRank
    FROM UserActivity
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalComments,
    Upvotes,
    Downvotes,
    Favorites,
    Questions,
    Answers,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    PostRank,
    VoteRank
FROM TopUsers
WHERE PostRank <= 10 OR VoteRank <= 10
ORDER BY PostRank, VoteRank;
