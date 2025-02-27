WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        p.Body,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagNames,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.ExcerptPostId 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.ViewCount,
        rp.Score,
        rp.TagNames,
        us.DisplayName AS OwnerDisplayName,
        us.Reputation AS OwnerReputation    
    FROM 
        RankedPosts rp
    JOIN 
        Users us ON rpPostOwnerId = us.Id
    WHERE 
        rp.UserPostRank <= 5  -- Top 5 posts per user
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.LastActivityDate,
    tp.ViewCount,
    tp.Score,
    tp.TagNames,
    tp.OwnerDisplayName,
    tp.OwnerReputation,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
    COUNT(DISTINCT c.Id) AS TotalComments,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = tp.PostId AND v.VoteTypeId IN (2, 3)) AS UpvoteDownvoteCount
FROM 
    TopPosts tp
LEFT JOIN 
    Votes v ON tp.PostId = v.PostId AND v.VoteTypeId IN (2, 3) -- Upvotes and downvotes
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.LastActivityDate, tp.ViewCount, tp.Score, 
    tp.TagNames, tp.OwnerDisplayName, tp.OwnerReputation
ORDER BY 
    tp.ViewCount DESC, 
    tp.Score DESC
LIMIT 50;
