WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(b.Name, 'No Badge') AS UserBadge,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1 -- Gold badges
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.Id, b.Name
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.VoteTypeId,
        COUNT(*) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        v.PostId, v.VoteTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.Rank,
    rp.UserBadge,
    rp.CommentCount,
    COALESCE(SUM(rv.VoteCount) FILTER (WHERE rv.VoteTypeId = 2), 0) AS UpVotes,
    COALESCE(SUM(rv.VoteCount) FILTER (WHERE rv.VoteTypeId = 3), 0) AS DownVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.Score DESC
LIMIT 10;
