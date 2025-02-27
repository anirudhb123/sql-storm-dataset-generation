
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer'
            ELSE 'Not Accepted Answer'
        END AS AcceptanceStatus
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score, p.AcceptedAnswerId, p.PostTypeId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostLinkStatistics AS (
    SELECT 
        pl.PostId,
        COUNT(pl.Id) AS RelatedPostCount,
        MAX(CASE WHEN lt.Name = 'Duplicate' THEN 1 ELSE 0 END) AS ContainsDuplicateLinks
    FROM 
        PostLinks pl
    JOIN LinkTypes lt ON pl.LinkTypeId = lt.Id
    GROUP BY 
        pl.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    pls.RelatedPostCount,
    CASE 
        WHEN pls.ContainsDuplicateLinks = 1 THEN 'Yes'
        ELSE 'No'
    END AS HasDuplicates,
    rp.AcceptanceStatus
FROM 
    RankedPosts rp
JOIN 
    UserBadges ub ON rp.PostId = ub.UserId  
LEFT JOIN 
    PostLinkStatistics pls ON rp.PostId = pls.PostId
WHERE 
    (rp.ViewCount > 100 OR rp.CommentCount > 5) 
    AND (rp.AcceptanceStatus = 'Accepted Answer' OR rp.Score < 0)
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
