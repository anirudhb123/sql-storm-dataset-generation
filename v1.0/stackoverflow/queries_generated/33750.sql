WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
),
AggregatedVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        Users u 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentComments AS (
    SELECT 
        c.PostId,
        c.Text,
        c.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY c.PostId ORDER BY c.CreationDate DESC) AS CommentRank
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= DATEADD(month, -2, GETDATE())
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    COALESCE(av.UpVotes, 0) AS UpVotes,
    COALESCE(av.DownVotes, 0) AS DownVotes,
    COALESCE(av.TotalVotes, 0) AS TotalVotes,
    us.BadgeCount,
    us.TotalReputation,
    rc.Text AS RecentComment,
    rc.CreationDate AS RecentCommentDate
FROM 
    RankedPosts rp
LEFT JOIN 
    AggregatedVotes av ON rp.PostId = av.PostId
LEFT JOIN 
    UserStats us ON us.UserId = (
        SELECT OwnerUserId 
        FROM Posts 
        WHERE Id = rp.PostId
    )
LEFT JOIN 
    RecentComments rc ON rc.PostId = rp.PostId AND rc.CommentRank = 1
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.Score DESC, rp.PostCreationDate ASC;
