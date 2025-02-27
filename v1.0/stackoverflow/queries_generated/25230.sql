WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.AnswerCount, 
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
        AND p.CreationDate >= NOW() - INTERVAL '30 days'
),
FilteredPosts AS (
    SELECT 
        rp.*,
        STRING_AGG(DISTINCT t.TagName, ', ') AS AllTags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Tags t ON t.Id = ANY(STRING_TO_ARRAY(SUBSTRING(rp.Tags, 2, LENGTH(rp.Tags) - 2), '><')::int[])
    WHERE 
        rp.RN <= 3
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.AnswerCount, rp.Tags
),
UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgePoints
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.AnswerCount,
    fp.AllTags,
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalBadgePoints
FROM 
    FilteredPosts fp
JOIN 
    Users u ON u.Id = fp.OwnerUserId
JOIN 
    UserStats us ON us.UserId = u.Id
ORDER BY 
    fp.ViewCount DESC, us.TotalBadgePoints DESC
LIMIT 10;
