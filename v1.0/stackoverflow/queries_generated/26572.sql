WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        SUM(v.VoteTypeId = 10) AS TotalDeletions,
        SUM(v.VoteTypeId = 11) AS TotalUndeletions
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        COUNT(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 END) AS TotalWikiPosts,
        AVG(EXTRACT(EPOCH FROM p.LastActivityDate - p.CreationDate) / 3600.0) AS AvgTimeToFirstResponse
    FROM Posts p
    GROUP BY p.OwnerUserId
),
EngagementRank AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.TotalPosts,
        ue.TotalComments,
        ue.TotalBadges,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.TotalWikiPosts,
        ps.AvgTimeToFirstResponse,
        (ue.UpVotes - ue.DownVotes) AS NetVotes
    FROM UserEngagement ue
    LEFT JOIN PostStatistics ps ON ue.UserId = ps.OwnerUserId
)
SELECT 
    EngagementRank.*,
    RANK() OVER (ORDER BY EngagementRank.NetVotes DESC, EngagementRank.TotalPosts DESC) AS EngagementRank,
    CASE 
        WHEN ue.TotalPosts = 0 THEN 0
        ELSE ROUND((ue.TotalComments * 100.0 / ue.TotalPosts), 2)
    END AS Comment-to-PostRatio,
    CASE 
        WHEN ps.TotalQuestions > 0 THEN ROUND((ps.TotalAnswers * 1.0 / ps.TotalQuestions), 2)
        ELSE 0
    END AS Answer-to-QuestionRatio
FROM EngagementRank
ORDER BY EngagementRank.EngagementRank
FETCH FIRST 50 ROWS ONLY;
