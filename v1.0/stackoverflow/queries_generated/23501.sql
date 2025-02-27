WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        CASE 
            WHEN COUNT(DISTINCT p.Id) = 0 THEN 0
            ELSE AVG(v.BountyAmount) END AS AvgBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS TagPostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
OuterJoinedPostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        u.DisplayName AS OwnerDisplayName,
        ur.TotalBadges,
        ur.AvgBounty,
        pt.Name AS PostType
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    LEFT JOIN 
        UserReputation ur ON ur.UserId = u.Id
    LEFT JOIN 
        PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE Id = rp.PostId)
)
SELECT 
    opd.PostId,
    opd.Title,
    opd.CreationDate,
    opd.Score,
    CASE 
        WHEN opd.AvgBounty IS NULL THEN 'No Bounties'
        ELSE CONCAT('Avg Bounty: ', opd.AvgBounty)
    END AS BountyInfo,
    opd.TotalBadges,
    pt.TagName AS PopularTagName,
    COUNT(c.Id) AS CommentCount,
    CASE 
        WHEN EXISTS (SELECT 1 FROM PostHistory ph WHERE ph.PostId = opd.PostId AND ph.PostHistoryTypeId = 10) THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    OuterJoinedPostDetails opd
LEFT JOIN 
    Comments c ON c.PostId = opd.PostId
LEFT JOIN 
    PopularTags pt ON pt.TagPostCount > 0
WHERE 
    opd.Score > 10
GROUP BY 
    opd.PostId, opd.Title, opd.CreationDate, opd.Score, opd.AvgBounty, opd.TotalBadges, pt.TagName
ORDER BY 
    opd.Score DESC, COUNT(c.Id) DESC, opd.CreationDate DESC
LIMIT 100;
