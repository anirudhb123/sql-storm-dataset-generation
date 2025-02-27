WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only Questions
        AND p.CreationDate > NOW() - INTERVAL '1 year'
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- Bounty Start
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5  -- Only consider users with more than 5 posts
),
HighestRankedTags AS (
    SELECT 
        t.TagName,
        COUNT(rp.PostId) AS PostCount,
        AVG(rp.ViewCount) AS AvgViews,
        AVG(rp.Score) AS AvgScore
    FROM 
        RankedPosts rp
    JOIN 
        Tags t ON rp.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        rp.TagRank = 1  -- Only the highest-ranked post per tag
    GROUP BY 
        t.TagName
)
SELECT 
    au.DisplayName AS ActiveUser,
    au.PostCount,
    au.TotalBounties,
    hrt.TagName,
    hrt.PostCount AS TagPostCount,
    hrt.AvgViews,
    hrt.AvgScore
FROM 
    MostActiveUsers au
JOIN 
    HighestRankedTags hrt ON au.PostCount > 10  -- Focus on users with significant engagement
ORDER BY 
    au.PostCount DESC, 
    hrt.PostCount DESC
LIMIT 10;
