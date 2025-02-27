WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN b.Class = 1 THEN 'Gold'
            WHEN b.Class = 2 THEN 'Silver'
            WHEN b.Class = 3 THEN 'Bronze'
            ELSE 'No Badge'
        END AS BadgeType
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UserRank,
    rp.CommentCount,
    ur.DisplayName AS UserName,
    ur.Reputation,
    ur.BadgeType,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    CASE 
        WHEN rp.UpVoteCount > rp.DownVoteCount THEN 'Positive'
        WHEN rp.UpVoteCount < rp.DownVoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    Tags t ON t.ExcerptPostId = rp.PostId
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.UserRank, rp.CommentCount, ur.DisplayName, ur.Reputation, ur.BadgeType
HAVING 
    rp.UserRank = 1 AND (ur.Reputation IS NOT NULL OR ur.BadgeType != 'No Badge')
ORDER BY 
    rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
