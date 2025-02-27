WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER(PARTITION BY p.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) OVER(PARTITION BY p.Id) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) OVER(PARTITION BY p.Id) AS DownVoteCount,
        CASE 
            WHEN p.ClosedDate IS NOT NULL THEN 'Closed' 
            ELSE 'Open' 
        END AS PostStatus
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(ph.Comment, '; ') AS EditComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    pha.EditCount,
    pha.LastEditDate,
    pha.EditComments,
    rp.PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PostHistoryAnalysis pha ON rp.PostId = pha.PostId
WHERE 
    rp.PostRank = 1 -- Get only the latest post for each user
ORDER BY 
    rp.Score DESC,
    rp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY; -- Pagination
