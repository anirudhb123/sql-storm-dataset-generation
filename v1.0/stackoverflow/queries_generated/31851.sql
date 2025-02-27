WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentsCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
HighScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerUserId,
        rb.BadgeCount,
        rb.BadgeNames
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges rb ON rp.OwnerUserId = rb.UserId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    hsp.PostId,
    hsp.Title,
    hsp.CreationDate,
    hsp.ViewCount,
    hsp.Score,
    hsp.BadgeCount,
    ISNULL(hsp.BadgeNames, 'No badges') AS BadgeNames,
    COALESCE(upvotes, 0) AS TotalUpvotes,
    COALESCE(downvotes, 0) AS TotalDownvotes
FROM 
    HighScoringPosts hsp
LEFT JOIN 
    (SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id) v ON hsp.PostId = v.PostId
ORDER BY 
    hsp.Score DESC, hsp.CreationDate DESC;

