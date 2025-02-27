WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(p.TotalPosts, 0) AS TotalPosts,
        COALESCE(c.TotalComments, 0) AS TotalComments,
        COALESCE(v.TotalVotes, 0) AS TotalVotes,
        (COALESCE(p.TotalPosts, 0) + COALESCE(c.TotalComments, 0) + COALESCE(v.TotalVotes, 0)) AS EngagementScore
    FROM Users u
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            COUNT(*) AS TotalPosts
        FROM Posts
        GROUP BY OwnerUserId
    ) p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS TotalComments
        FROM Comments
        GROUP BY UserId
    ) c ON u.Id = c.UserId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS TotalVotes
        FROM Votes
        GROUP BY UserId
    ) v ON u.Id = v.UserId
),
HighEngagementUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalVotes,
        EngagementScore,
        RANK() OVER (ORDER BY EngagementScore DESC) AS Rank
    FROM UserEngagement
    WHERE EngagementScore > 0
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id
),
UserTopPosts AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes,
        pd.PostRank
    FROM HighEngagementUsers ue
    JOIN PostDetails pd ON ue.UserId = pd.OwnerUserId
    WHERE pd.PostRank <= 5 -- Get top 5 recent posts per user
)
SELECT 
    u.UserId,
    u.DisplayName,
    COUNT(DISTINCT p.PostId) AS TotalPosts,
    SUM(p.UpVotes) AS TotalUpVotes,
    SUM(p.DownVotes) AS TotalDownVotes
FROM UserTopPosts p
JOIN HighEngagementUsers u ON p.UserId = u.UserId
GROUP BY u.UserId, u.DisplayName
ORDER BY TotalPosts DESC, TotalUpVotes DESC;
