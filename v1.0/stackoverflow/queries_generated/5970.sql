WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT r.PostId) AS TotalPosts,
        SUM(r.AnswerCount) AS TotalAnswers,
        SUM(r.UpVotes) AS TotalUpVotes
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts r ON u.Id = r.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.TotalPosts,
    u.TotalAnswers,
    u.TotalUpVotes,
    COALESCE(SUM(b.Class), 0) AS TotalBadges
FROM 
    UserStats u
LEFT JOIN 
    Badges b ON u.UserId = b.UserId
GROUP BY 
    u.UserId, u.DisplayName, u.Reputation, u.TotalPosts, u.TotalAnswers, u.TotalUpVotes
ORDER BY 
    u.TotalUpVotes DESC
LIMIT 10;
