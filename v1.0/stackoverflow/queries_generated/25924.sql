WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2)  -- Filtering for Questions and Answers
),

TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(p.ViewCount) AS AverageViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.ViewCount,
    ts.PostCount AS TagPostCount,
    ts.AverageViews AS TagAverageViews,
    ua.PostsCreated,
    ua.CommentsMade,
    ua.TotalBounty
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStatistics ts ON ts.TagName = ANY(string_to_array(rp.Tags, '>'))  -- Assuming tags are stored in a 'greater than' formatted structure
LEFT JOIN 
    UserActivity ua ON ua.UserId = rp.OwnerUserId
WHERE 
    rp.Rank <= 10  -- Top 10 posts by view count per post type
ORDER BY 
    rp.PostTypeId, 
    rp.ViewCount DESC;
