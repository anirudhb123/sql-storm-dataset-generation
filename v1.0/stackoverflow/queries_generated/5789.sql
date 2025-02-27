WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rnk
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Upvote
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostAnalysis AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.VoteCount,
        us.UserId,
        us.DisplayName AS OwnerDisplayName,
        us.Reputation AS OwnerReputation,
        us.PostsCount,
        us.TotalBadges,
        us.TotalScore
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    WHERE 
        rp.Rnk <= 5 -- top 5 posts per user
)
SELECT 
    pa.Title,
    pa.CreationDate,
    pa.ViewCount,
    pa.Score,
    pa.CommentCount,
    pa.VoteCount,
    pa.OwnerDisplayName,
    pa.OwnerReputation,
    pa.PostsCount,
    pa.TotalBadges,
    pa.TotalScore
FROM 
    PostAnalysis pa
ORDER BY 
    pa.Score DESC, pa.ViewCount DESC;
