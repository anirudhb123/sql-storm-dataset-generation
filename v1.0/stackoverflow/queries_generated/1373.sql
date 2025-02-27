WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    us.TotalScore,
    COALESCE(rp.Title, 'No Posts') AS TopPostTitle,
    COALESCE(rp.Score, 0) AS TopPostScore,
    us.QuestionCount,
    CASE 
        WHEN us.TotalScore IS NULL THEN 'No Score'
        WHEN us.TotalScore > 500 THEN 'High Impact User'
        ELSE 'User Needs Engagement'
    END AS UserStatus
FROM 
    Users u
JOIN 
    UserScores us ON u.Id = us.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.Rank
WHERE 
    u.Location IS NULL 
    OR u.Location LIKE '%USA%' 
ORDER BY 
    us.TotalScore DESC, 
    u.Reputation DESC
LIMIT 100;

WITH RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        v.PostId
)
SELECT 
    p.Title,
    p.ViewCount,
    COALESCE(rv.Upvotes, 0) - COALESCE(rv.Downvotes, 0) AS VoteBalance,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
FROM 
    Posts p
LEFT JOIN 
    RecentVotes rv ON p.Id = rv.PostId
WHERE 
    p.CreationDate < NOW() - INTERVAL '6 months'
ORDER BY 
    VoteBalance DESC, 
    CommentCount DESC
LIMIT 50;
