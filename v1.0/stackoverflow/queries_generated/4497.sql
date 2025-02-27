WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.ViewCount IS NOT NULL
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        c.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    COALESCE(rc.CommentCount, 0) AS RecentComments,
    COALESCE(ub.BadgeCount, 0) AS GoldBadgeCount
FROM 
    Users u
INNER JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    RecentComments rc ON rp.Id = rc.PostId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;

WITH TotalVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostDetails AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(tv.UpVotes, 0) AS TotalUpVotes,
        COALESCE(tv.DownVotes, 0) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        TotalVotes tv ON p.Id = tv.PostId
)
SELECT 
    pd.Title,
    pd.TotalUpVotes - pd.TotalDownVotes AS NetVotes,
    CASE 
        WHEN pd.TotalUpVotes - pd.TotalDownVotes > 0 THEN 'Positive'
        WHEN pd.TotalUpVotes - pd.TotalDownVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    PostDetails pd
WHERE 
    pd.TotalUpVotes > pd.TotalDownVotes
ORDER BY 
    NetVotes DESC;
