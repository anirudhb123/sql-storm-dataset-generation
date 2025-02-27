WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),

PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        us.UserId,
        us.DisplayName,
        COALESCE(us.BadgeCount, 0) AS BadgeCount,
        COALESCE(us.TotalBounty, 0) AS TotalBounty
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users us ON rp.OwnerUserId = us.Id
)

SELECT 
    pd.Title,
    pd.CreationDate,
    pd.DisplayName,
    pd.BadgeCount,
    pd.TotalBounty,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pd.PostId) AS CommentCount,
    (SELECT SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) FROM Votes v WHERE v.PostId = pd.PostId) AS UpVoteCount,
    (SELECT SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) FROM Votes v WHERE v.PostId = pd.PostId) AS DownVoteCount
FROM 
    PostDetails pd
WHERE 
    pd.PostRank = 1
ORDER BY 
    pd.TotalBounty DESC
LIMIT 10;
