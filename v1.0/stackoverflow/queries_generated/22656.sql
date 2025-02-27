WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.ViewCount > 100
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.PostTypeId
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        MIN(ph.Comment) AS CloseComment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Closed or Reopened
    GROUP BY 
        ph.PostId, ph.UserId, ph.CreationDate
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    COALESCE(cp.CloseComment, 'No closure comments') AS ClosureDescription,
    rp.CreationDate,
    CASE 
        WHEN rp.Rank <= 5 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.CommentCount > 0
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 50;

WITH TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(t.Count) AS TotalCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id, t.TagName
),
ExcessiveTags AS (
    SELECT 
        ts.TagId,
        ts.TagName,
        ts.PostCount,
        ts.TotalCount,
        NTILE(4) OVER (ORDER BY ts.TotalCount DESC) AS Quartile
    FROM 
        TagStats ts
    WHERE 
        ts.PostCount > 10
)

SELECT 
    et.TagId,
    et.TagName,
    et.PostCount,
    et.TotalCount,
    et.Quartile,
    CASE 
        WHEN et.Quartile = 1 THEN 'Very Active Tags'
        WHEN et.Quartile = 2 THEN 'Active Tags'
        WHEN et.Quartile = 3 THEN 'Less Active Tags'
        ELSE 'Rarely Used Tags'
    END AS TagActivityLevel
FROM 
    ExcessiveTags et
WHERE 
    et.TotalCount IS NOT NULL
ORDER BY 
    et.TotalCount DESC;

SELECT 
    u.Id,
    u.DisplayName,
    u.Reputation,
    u.Location,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
    COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
    COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, u.Location
HAVING 
    COUNT(DISTINCT b.Id) > 5
ORDER BY 
    u.Reputation DESC
LIMIT 30;

SELECT 
    DISTINCT p.Title,
    CASE 
        WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Has an Accepted Answer'
        ELSE 'No Accepted Answer'
    END AS AnswerStatus,
    COUNT(co.Id) AS CommentCount
FROM 
    Posts p
LEFT JOIN 
    Comments co ON p.Id = co.PostId
WHERE 
    p.CreationDate < (NOW() - INTERVAL '6 months')
    AND p.AnswerCount > 0
GROUP BY 
    p.Title, p.AcceptedAnswerId
HAVING 
    COUNT(co.Id) = 0 OR AVG(co.Score) < 0
ORDER BY 
    p.CreationDate DESC;
