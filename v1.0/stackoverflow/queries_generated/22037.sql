WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentTotal,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate ASC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1 -- Only questions
),
UserResults AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostClosureStats AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        COUNT(DISTINCT ph.Id) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS ClosureCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.UserId
),
ActivePosts AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title AS PostTitle,
        COUNT(pl.RelatedPostId) AS RelatedLinks,
        COALESCE(cs.ClosureCount, 0) AS ClosureCount,
        cs.LastClosedDate,
        cs.LastReopenedDate,
        ur.DisplayName AS OwnerDisplayName,
        ur.TotalPosts,
        ur.TotalViews
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostLinks pl ON rp.Id = pl.PostId
    LEFT JOIN 
        PostClosureStats cs ON rp.Id = cs.PostId
    JOIN 
        Users ur ON rp.Id = ur.Id
    WHERE 
        rp.RankScore <= 100
    GROUP BY 
        rp.Id, rp.Title, cs.ClosureCount, 
        cs.LastClosedDate, cs.LastReopenedDate, <br> ur.DisplayName, ur.TotalPosts, ur.TotalViews
)
SELECT 
    ap.PostId,
    ap.PostTitle,
    ap.RelatedLinks,
    ap.ClosureCount,
    ap.LastClosedDate,
    ap.LastReopenedDate,
    ap.OwnerDisplayName,
    ap.TotalPosts,
    ap.TotalViews
FROM 
    ActivePosts ap
WHERE 
    (ap.ClosureCount > 0 OR ap.LastClosedDate IS NOT NULL) 
    AND (ap.ViewCount > 100 OR ap.TotalPosts > 5)
ORDER BY 
    ap.ClosureCount DESC,
    ap.ViewCount DESC,
    ap.LastClosedDate DESC
LIMIT 50;
