WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
),
AggregatedUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8
    GROUP BY 
        u.Id
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(rc.CommentCount, 0) AS CommentCount,
        COALESCE(rc.LastCommentDate, '1900-01-01') AS LastCommentDate,
        COUNT(h.Id) AS EditCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        MAX(h.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        RecentComments rc ON p.Id = rc.PostId
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId AND h.PostHistoryTypeId IN (4, 5, 6)  -- Title, Body, Tags edited
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    aus.UserId,
    aus.DisplayName,
    aus.TotalQuestions,
    aus.TotalBadges,
    aus.TotalBounty,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    pa.CommentCount,
    pa.LastCommentDate,
    pa.EditCount,
    pa.VoteCount
FROM 
    AggregatedUserStats aus
JOIN 
    RankedPosts rp ON aus.UserId = rp.OwnerUserId
JOIN 
    PostActivity pa ON rp.PostId = pa.PostId
WHERE 
    rp.PostRank <= 5 -- Top 5 posts for each user
ORDER BY 
    aus.TotalBounty DESC, -- Order by total bounty to see which users have engaging posts
    rp.Score DESC;
