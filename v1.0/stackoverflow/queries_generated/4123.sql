WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotesCount,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
CommentStats AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.UserRank,
    rp.ViewCount,
    cs.CommentCount,
    cs.LastCommentDate,
    us.DisplayName,
    us.Reputation,
    us.BadgeCount,
    CASE 
        WHEN rp.UpVotesCount > rp.DownVotesCount THEN 'Positive'
        WHEN rp.UpVotesCount < rp.DownVotesCount THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    RankedPosts rp
LEFT JOIN 
    CommentStats cs ON rp.PostId = cs.PostId
LEFT JOIN 
    UserStats us ON rp.UserRank = 1
WHERE 
    rp.UserRank <= 5
ORDER BY 
    rp.Score DESC;
