WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    ts.PostCount AS RelatedTagPostCount,
    ts.AcceptedAnswerCount AS RelatedTagAcceptedAnswerCount,
    ur.TotalBounty,
    ur.BadgeCount,
    CASE 
        WHEN rp.ScoreRank = 1 THEN 'Top Post'
        WHEN rp.ScoreRank <= 10 THEN 'High Performer'
        ELSE 'Regular Post'
    END AS PerformanceCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStats ts ON rp.Title LIKE '%' || ts.TagName || '%'
LEFT JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
WHERE 
    ur.BadgeCount > 0
    AND ur.TotalBounty >= 50
ORDER BY 
    rp.Score DESC,
    rp.ViewCount DESC,
    ts.PostCount DESC
LIMIT 100;

-- This query includes CTEs for post ranking, tag stats aggregation, and user reputation. 
-- It showcases outer joins for relationships, complex calculations for performance categorization,
-- and filtering based on aggregate results. The results draw a picture of high-impact content
-- and its relationship with engaged users and tag usage, all while leveraging SQL's advanced
-- query capabilities for in-depth analysis.
