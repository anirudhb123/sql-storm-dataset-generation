WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id
), UserRankedPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        rp.*,
        RANK() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS GlobalRank
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
)
SELECT 
    urp.UserId,
    urp.DisplayName,
    urp.PostId,
    urp.Title,
    urp.CreationDate,
    urp.Score,
    urp.ViewCount,
    urp.CommentCount,
    urp.VoteCount,
    urp.GlobalRank
FROM 
    UserRankedPosts urp
WHERE 
    urp.GlobalRank <= 10
ORDER BY 
    urp.GlobalRank;
