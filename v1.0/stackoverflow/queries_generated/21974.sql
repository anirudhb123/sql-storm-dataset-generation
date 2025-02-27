WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        AVG(COALESCE(NULLIF(p.Score,0), 1)) AS AvgScore -- Avoid division by zero by using 1 if score is zero
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostInteractionHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeletionCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS EditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.UserId
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(pi.CloseReopenCount, 0) AS CloseReopenCount,
        COALESCE(pi.DeletionCount, 0) AS DeletionCount,
        COALESCE(pi.EditCount, 0) AS EditCount,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        PostInteractionHistory pi ON p.Id = pi.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.AnswerCount, pi.CloseReopenCount, pi.DeletionCount, pi.EditCount
)
SELECT 
    u.DisplayName,
    u.Reputation,
    us.TotalUpVotes - us.TotalDownVotes AS NetVotes,
    STRING_AGG(DISTINCT CONCAT('Post: ', pm.Title, ' (View Count: ', pm.ViewCount, ', Answer Count: ', pm.AnswerCount, ')'), '; ') AS PostSummary,
    AVG(pm.TotalUpVotes) AS AvgPostUpVotes,
    COUNT(pm.PostId) AS PostsEngaged
FROM 
    Users u
JOIN 
    UserVoteStats us ON u.Id = us.UserId
JOIN 
    PostMetrics pm ON u.Id = pm.OwnerUserId -- Assuming the final output includes only posts that the user has owned
WHERE 
    u.Reputation > 1000
    AND us.TotalPosts > 5
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(pm.PostId) > 0
ORDER BY 
    u.Reputation DESC, NetVotes DESC;

