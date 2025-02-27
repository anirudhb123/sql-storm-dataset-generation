WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(vt.UpVotes) - SUM(vt.DownVotes), 0) AS NetVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        AVG(COALESCE(DATEDIFF('day', p.CreationDate, NOW()), 0)) AS AvgDaysActive
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes vt ON p.Id = vt.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.LastActivityDate >= NOW() - INTERVAL '30 days'
),
AccumulatedVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)

SELECT 
    us.DisplayName,
    us.Reputation,
    us.NetVotes,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.AvgDaysActive,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    av.UpVotes,
    av.DownVotes
FROM 
    UserStats us
LEFT JOIN 
    RecentPosts rp ON us.UserId = rp.OwnerUserId AND rp.RecentRank = 1
LEFT JOIN 
    AccumulatedVotes av ON rp.Id = av.PostId
ORDER BY 
    us.Reputation DESC, us.NetVotes DESC
LIMIT 10;
