WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges,
        SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        Questions, 
        Answers, 
        AcceptedAnswers, 
        UpVotes, 
        DownVotes, 
        GoldBadges, 
        SilverBadges, 
        BronzeBadges, 
        ClosedPosts,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        UserStatistics
)
SELECT 
    Rank,
    DisplayName,
    TotalPosts,
    Questions, 
    Answers, 
    AcceptedAnswers,
    UpVotes,
    DownVotes,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    ClosedPosts
FROM 
    TopUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
