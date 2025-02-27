WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(u.Reputation, 0) AS UserReputation,
        COALESCE(b.Name, 'No Badge') AS UserBadge
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1 -- Gold badges
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Posts from the last year
    GROUP BY 
        p.Id, u.Reputation, b.Name
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.Tags,
        rp.UserReputation,
        rp.UserBadge
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1
    ORDER BY 
        rp.ViewCount DESC
    LIMIT 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.Tags,
    tp.UserReputation,
    tp.UserBadge,
    COUNT(v.Id) AS Upvotes,
    ARRAY_AGG(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.UserId END) AS VotedUserIds
FROM 
    TopPosts tp
LEFT JOIN 
    Votes v ON tp.PostId = v.PostId AND v.VoteTypeId = 2 -- Count Upvotes
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.ViewCount, tp.Score, tp.CommentCount, tp.Tags, tp.UserReputation, tp.UserBadge
ORDER BY 
    Upvotes DESC;
