WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND -- Only consider questions
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Within the last year
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryCreationDate,
        pht.Name AS HistoryType,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= DATEADD(month, -6, GETDATE()) -- Within the last 6 months
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
PopularTags AS (
    SELECT 
        tags.Id,
        tags.TagName,
        COUNT(p.Id) AS Popularity
    FROM 
        Tags tags
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' + tags.TagName + '%'
    GROUP BY 
        tags.Id, tags.TagName
    HAVING 
        COUNT(p.Id) > 10 -- Tags must be associated with more than 10 posts
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.OwnerDisplayName,
    ph.HistoryCreationDate,
    ph.HistoryType,
    ph.UserDisplayName AS EditorDisplayName,
    ph.Comment AS EditComment,
    ub.GoldBadges, 
    ub.SilverBadges, 
    ub.BronzeBadges,
    pt.TagName,
    pt.Popularity
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PopularTags pt ON pt.Popularity > 20 -- Filters to only popular tags for final selection
WHERE 
    rp.PostRank = 1 -- Selecting only the highest score question per user
    AND (ph.HistoryType IS NOT NULL OR (pt.TagName IS NOT NULL AND pt.Popularity > 20)) -- Ensures there is edit history or popular tags
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
