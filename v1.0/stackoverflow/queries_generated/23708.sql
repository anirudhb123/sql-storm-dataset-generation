WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (8, 9) -- Summing only BountyStart and BountyClose votes
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month' 
        AND p.PostTypeId IN (1, 2) -- Only questions and answers
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        u.Reputation > 1000 -- Only users with more than 1000 reputation
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(t.Id) AS TagCount
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1 -- Only questions
    GROUP BY 
        t.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.RankByViews,
    ub.DisplayName AS Author,
    ub.BadgeCount,
    pt.FirstEditDate,
    pt.ClosedDate,
    COALESCE(pt.ClosedDate, 'Not Closed') AS Status,
    STRING_AGG(pt.TagCount || ' ' || pt.TagName, ', ') AS PopularTags
FROM 
    RankedPosts rp
JOIN 
    UserBadges ub ON ub.UserId = rp.OwnerUserId
LEFT JOIN 
    PostHistoryDetails pt ON pt.PostId = rp.PostId
LEFT JOIN 
    PopularTags ptg ON ptg.TagName = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))
WHERE 
    rp.RankByViews <= 5 -- Top 5 posts per user
GROUP BY 
    rp.PostId, ub.DisplayName, ub.BadgeCount, pt.FirstEditDate, pt.ClosedDate
ORDER BY 
    rp.ViewCount DESC;
