WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS UserPostCount,
        AVG(p.Score) AS AvgPostScore,
        COUNT(DISTINCT p.Tags) AS UniqueTagCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Id END) AS TimesClosed
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBadges,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.UpVotesReceived,
    ua.DownVotesReceived,
    ps.UserPostCount,
    ps.AvgPostScore,
    ps.UniqueTagCount,
    ps.TimesClosed
FROM 
    UserActivity ua
LEFT JOIN 
    PostStats ps ON ua.UserId = ps.OwnerUserId
WHERE 
    ua.Reputation > 1000
ORDER BY 
    ua.Reputation DESC, ua.TotalPosts DESC;
