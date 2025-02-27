WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS CommentRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class) AS TotalBadges,
        SUM(b.Date > NOW() - INTERVAL '1 year') AS RecentBadges,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    ur.UserId,
    ur.TotalBadges,
    ur.RecentBadges,
    ur.AvgReputation
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.CommentCount > 0
JOIN 
    UserReputation ur ON u.Id = rp.CommentRank -- Joining based on the rank derived from comments
WHERE 
    rp.CommentRank <= 5 -- Top 5 Posts per user
ORDER BY 
    ur.AvgReputation DESC, rp.CommentCount DESC;
