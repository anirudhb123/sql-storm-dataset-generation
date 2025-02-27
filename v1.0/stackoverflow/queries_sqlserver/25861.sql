
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.OwnerUserId, p.ViewCount
),
PopularTags AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS UseCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '> <') 
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        value
    ORDER BY 
        UseCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        AVG(p.ViewCount) AS AvgPostViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 10
)
SELECT 
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    pt.TagName,
    um.DisplayName,
    um.GoldBadges,
    um.SilverBadges,
    um.BronzeBadges,
    um.TotalPosts,
    um.AvgPostViews
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.Tags LIKE '%' + pt.TagName + '%'
JOIN 
    UserMetrics um ON rp.OwnerUserId = um.UserId
ORDER BY 
    rp.ViewCount DESC, 
    rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
