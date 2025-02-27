WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.TagCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- We are interested in Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
MaxVotes AS (
    SELECT 
        vp.PostId,
        COUNT(vp.Id) AS VoteCount
    FROM 
        Votes vp
    WHERE 
        vp.VoteTypeId IN (2, 3) -- Considering only upvotes and downvotes
    GROUP BY 
        vp.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ra.PostRank,
    ra.Title,
    ra.CreationDate,
    ra.Score,
    ra.ViewCount,
    mv.VoteCount,
    ua.DisplayName AS UserDisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBadges,
    ra.Tags
FROM 
    RankedPosts ra
LEFT JOIN 
    MaxVotes mv ON ra.PostId = mv.PostId
JOIN 
    UserActivity ua ON ra.OwnerUserId = ua.UserId
WHERE 
    ra.PostRank = 1
  AND 
    ra.CreationDate >= NOW() - INTERVAL '1 year' 
ORDER BY 
    ra.Score DESC, 
    ra.ViewCount DESC;
