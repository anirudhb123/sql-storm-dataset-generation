WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), PostWithTags AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        t.TagName,
        COALESCE(ph.Comment, 'No comments') AS LastEditComment
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts_tags tag_link ON rp.PostId = tag_link.PostId
    LEFT JOIN 
        Tags t ON tag_link.TagId = t.Id
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId AND ph.PostHistoryTypeId IN (4, 5) -- Title or Body edits
    WHERE 
        rp.PostRank = 1
), UsersAggregate AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBountySpent
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
), CommentsCount AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COALESCE(cc.CommentCount, 0) AS TotalComments,
    STRING_AGG(DISTINCT pwt.TagName, ', ') AS Tags
FROM 
    UsersAggregate ua
JOIN 
    PostWithTags p ON p.OwnerUserId = ua.UserId
LEFT JOIN 
    CommentsCount cc ON p.PostId = cc.PostId
WHERE 
    ua.Reputation > 100
GROUP BY 
    ua.DisplayName, ua.Reputation, p.Title, p.CreationDate, p.Score, p.ViewCount
HAVING 
    COUNT(p.PostId) > 5
ORDER BY 
    p.Score DESC NULLS LAST
LIMIT 10;
