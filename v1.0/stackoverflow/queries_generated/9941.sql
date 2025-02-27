WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes,
        SUM(b.Class = 1) AS TotalGoldBadges,
        SUM(b.Class = 2) AS TotalSilverBadges,
        SUM(b.Class = 3) AS TotalBronzeBadges
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
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalUpVotes,
        TotalDownVotes,
        TotalGoldBadges,
        TotalSilverBadges,
        TotalBronzeBadges,
        RANK() OVER (ORDER BY TotalPosts DESC) AS RankByPosts,
        RANK() OVER (ORDER BY TotalUpVotes DESC) AS RankByUpVotes,
        RANK() OVER (ORDER BY TotalGoldBadges DESC) AS RankByGoldBadges
    FROM 
        UserPostStats
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalUpVotes,
    TotalDownVotes,
    TotalGoldBadges,
    TotalSilverBadges,
    TotalBronzeBadges,
    RankByPosts,
    RankByUpVotes,
    RankByGoldBadges
FROM 
    RankedUsers
WHERE 
    (TotalPosts > 0 OR TotalUpVotes > 0)
ORDER BY 
    RankByPosts, RankByUpVotes;
