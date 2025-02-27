
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
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
        UpVotes, 
        DownVotes, 
        TotalBadges,
        @rankByPosts := IF(@prevTotalPosts = TotalPosts, @rankByPosts, @rankByPosts + 1) AS RankByPosts,
        @prevTotalPosts := TotalPosts,
        @rankByReputation := IF(@prevReputation = UpVotes - DownVotes, @rankByReputation, @rankByReputation + 1) AS RankByReputation,
        @prevReputation := UpVotes - DownVotes
    FROM 
        UserStats, (SELECT @rankByPosts := 0, @prevTotalPosts := NULL, @rankByReputation := 0, @prevReputation := NULL) AS init
    ORDER BY 
        TotalPosts DESC, UpVotes - DownVotes DESC
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.TotalPosts,
    t.Questions,
    t.Answers,
    t.UpVotes,
    t.DownVotes,
    t.TotalBadges,
    t.RankByPosts,
    t.RankByReputation
FROM 
    TopUsers t
WHERE 
    t.RankByPosts <= 10
ORDER BY 
    t.RankByReputation DESC, t.RankByPosts ASC;
