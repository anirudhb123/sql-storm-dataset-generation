WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount,
        COALESCE(MAX(p.CreationDate), NOW()) AS LastActivity
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        us.AnswerCount,
        us.BadgeCount,
        pe.PostId,
        pe.Title,
        pe.CommentCount,
        pe.UpVoteCount,
        pe.DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY us.UserId ORDER BY us.Reputation DESC) AS Rank
    FROM 
        UserStats us
    JOIN 
        PostEngagement pe ON us.PostCount > 0
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.AnswerCount,
    tu.BadgeCount,
    tu.Title,
    tu.CommentCount,
    tu.UpVoteCount,
    tu.DownVoteCount
FROM 
    TopUsers tu
WHERE 
    tu.Rank = 1
ORDER BY 
    tu.Reputation DESC, 
    tu.AnswerCount DESC;
