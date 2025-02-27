WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) OVER() AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.Id
),
ClosedPostStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    ups.DisplayName,
    ups.TotalPosts,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.AverageReputation,
    pvs.VoteCount,
    pvs.UpVotes,
    pvs.DownVotes,
    cps.CloseCount,
    cps.ReopenCount
FROM 
    UserPostStats ups
LEFT JOIN 
    PostVoteStats pvs ON ups.UserId = (SELECT OwnerUserId FROM Posts WHERE Posts.Id = pvs.PostId)
LEFT JOIN 
    ClosedPostStats cps ON cps.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ups.UserId)
WHERE 
    ups.TotalPosts > 0
ORDER BY 
    ups.AverageReputation DESC, 
    ups.TotalPosts DESC
LIMIT 10;
