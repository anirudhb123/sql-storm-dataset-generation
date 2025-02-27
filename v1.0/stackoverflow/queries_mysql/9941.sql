
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS TotalGoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS TotalSilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS TotalBronzeBadges
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
        @rankByPosts := IF(@prevPosts = TotalPosts, @rankByPosts, @rowNumber) AS RankByPosts,
        @prevPosts := TotalPosts,
        @rankByVotes := IF(@prevVotes = TotalUpVotes, @rankByVotes, @rowNumber) AS RankByUpVotes,
        @prevVotes := TotalUpVotes,
        @rankByGold := IF(@prevGold = TotalGoldBadges, @rankByGold, @rowNumber) AS RankByGoldBadges,
        @prevGold := TotalGoldBadges,
        @rowNumber := @rowNumber + 1
    FROM 
        UserPostStats, (SELECT @rowNumber := 1, @prevPosts := NULL, @rankByPosts := 1, @prevVotes := NULL, @rankByVotes := 1, @prevGold := NULL, @rankByGold := 1) AS vars
    ORDER BY 
        TotalPosts DESC, TotalUpVotes DESC, TotalGoldBadges DESC
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
