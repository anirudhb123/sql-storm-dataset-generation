WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
PopularPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.Upvotes,
        ps.Downvotes,
        ps.CommentCount,
        ps.BadgeCount,
        RANK() OVER (ORDER BY ps.ViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY ps.Upvotes - ps.Downvotes DESC) AS VoteRank
    FROM 
        PostStats ps
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.Upvotes,
    pp.Downvotes,
    pp.CommentCount,
    pp.BadgeCount
FROM 
    PopularPosts pp
WHERE 
    pp.ViewRank <= 10 OR pp.VoteRank <= 10
ORDER BY 
    pp.ViewCount DESC, pp.Upvotes - pp.Downvotes DESC;
