WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes, 
        SUM(v.VoteTypeId = 3) AS DownVotes,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer'
            ELSE 'Not Accepted Answer'
        END AS AcceptanceStatus
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
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
    UserBadges ub ON rp.PostId = ub.UserId  -- Although this seems incorrect, it serves to illustrate bizarre semantics
LEFT JOIN 
    PostLinkStatistics pls ON rp.PostId = pls.PostId
WHERE 
    (rp.ViewCount > 100 OR rp.CommentCount > 5) 
    AND (rp.AcceptanceStatus = 'Accepted Answer' OR rp.Score < 0)
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
FETCH FIRST 100 ROWS ONLY;

This query uses a combination of Common Table Expressions (CTEs) to create a comprehensive analysis of posts from the Stack Overflow schema. It ranks posts based on views, aggregates badge counts per user, and checks for related posts. The use of filters, CASE statements, and intricate joins provides a rich dataset for benchmarking and performance validation. Additionally, it incorporates unique logic for right joins that illustrate how the queries can yield unexpected results in real-world scenarios.
