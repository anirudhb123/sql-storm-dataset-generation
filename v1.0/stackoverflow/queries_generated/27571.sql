WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.Score > 0   -- Only popular questions
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
CombinedAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Author,
        ts.TagName,
        ts.TagCount,
        ub.BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        TagStatistics ts ON rp.PostId IN (SELECT PostId FROM Posts WHERE Tags LIKE '%' || ts.TagName || '%')
    JOIN 
        UserBadges ub ON rp.PostId = ub.UserId
)
SELECT 
    ca.PostId,
    ca.Title,
    ca.Body,
    ca.CreationDate,
    ca.Score,
    ca.ViewCount,
    ca.Author,
    ca.TagName,
    ca.TagCount,
    ca.BadgeCount,
    COUNT(c.Id) AS CommentCount
FROM 
    CombinedAnalytics ca
LEFT JOIN 
    Comments c ON c.PostId = ca.PostId
GROUP BY 
    ca.PostId, ca.Title, ca.Body, ca.CreationDate, ca.Score, ca.ViewCount, ca.Author, ca.TagName, ca.TagCount, ca.BadgeCount
ORDER BY 
    ca.Score DESC, ca.ViewCount DESC
LIMIT 50;
