WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id, u.Reputation
),
PostSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        us.UserId,
        us.Reputation,
        us.TotalBounties,
        us.BadgeCount,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON u.Id = rp.OwnerUserId
    JOIN 
        UserStats us ON us.UserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON c.PostId = rp.PostId
)
SELECT 
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.AnswerCount,
    ps.Reputation,
    ps.TotalBounties,
    ps.BadgeCount,
    ps.CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ps.PostId AND v.VoteTypeId = 2) AS Upvotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ps.PostId AND v.VoteTypeId = 3) AS Downvotes
FROM 
    PostSummary ps
WHERE 
    ps.AnswerCount > 0 AND 
    ps.Reputation > 1000
ORDER BY 
    ps.ViewCount DESC, ps.CreationDate DESC
LIMIT 10;

