WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.LastActivityDate, p.OwnerUserId
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount -- Closed posts count
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '2 years'
    GROUP BY 
        u.Id, u.Reputation
),
FinalMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.RankByScore,
        rp.CommentCount,
        rp.TotalUpVotes,
        rp.TotalDownVotes,
        um.UserId,
        um.Reputation,
        um.BadgeCount,
        um.CloseCount,
        CASE 
            WHEN um.Reputation > 100 THEN 'Experienced'
            WHEN um.Reputation BETWEEN 50 AND 100 THEN 'Intermediate'
            ELSE 'Novice' 
        END AS UserLevel
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    JOIN 
        UserMetrics um ON u.Id = um.UserId
)
SELECT 
    f.PostId,
    f.Title,
    f.Score,
    f.CreationDate,
    f.LastActivityDate,
    f.RankByScore,
    f.CommentCount,
    f.TotalUpVotes,
    f.TotalDownVotes,
    f.UserId,
    f.Reputation,
    f.BadgeCount,
    f.CloseCount,
    f.UserLevel
FROM 
    FinalMetrics f
WHERE 
    f.RankByScore <= 3 -- Top 3 posts per user
ORDER BY 
    f.Score DESC NULLS LAST, -- Consider NULL scores at the end
    f.UserLevel ASC,
    f.CreationDate DESC;

-- Include a UNION with posts that have an unusual number of edits compared to their score
UNION ALL

SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.CreationDate,
    p.LastActivityDate,
    NULL AS RankByScore,
    NULL AS CommentCount,
    NULL AS TotalUpVotes,
    NULL AS TotalDownVotes,
    p.OwnerUserId,
    u.Reputation,
    NULL AS BadgeCount,
    NULL AS CloseCount,
    CASE 
        WHEN u.Reputation < 0 THEN 'Suspended'
        ELSE 'Active'
    END AS UserLevel
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = p.Id) > (p.Score + 5) -- More edits than score +5
    AND p.Score < 0 -- Only consider negative scoring posts
ORDER BY 
    CreationDate DESC;
