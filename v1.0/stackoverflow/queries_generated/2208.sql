WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.BadgeCount,
        ur.PostCount,
        ur.TotalScore,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC, ur.TotalScore DESC) AS rn
    FROM 
        UserReputation ur
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.BadgeCount,
    COALESCE(rp.Title, 'No Posts') AS RecentPostTitle,
    COALESCE(rp.CreationDate, 'N/A') AS RecentPostDate,
    COALESCE(rp.Score, 0) AS RecentPostScore
FROM 
    TopUsers tu
JOIN 
    Users u ON tu.UserId = u.Id
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.PostId
WHERE 
    tu.rn <= 10
ORDER BY 
    u.Reputation DESC, 
    u.BadgeCount DESC;

-- Additional Information
WITH PostStats AS (
    SELECT 
        p.Id,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ps.Id,
    ps.UpVotes,
    ps.DownVotes,
    ps.CommentCount,
    ps.EditCount,
    CASE 
        WHEN ps.UpVotes > ps.DownVotes THEN 'Positive'
        WHEN ps.UpVotes < ps.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS PostSentiment
FROM 
    PostStats ps
WHERE 
    ps.UpVotes > 0 OR ps.DownVotes > 0
ORDER BY 
    ps.UpVotes DESC;
