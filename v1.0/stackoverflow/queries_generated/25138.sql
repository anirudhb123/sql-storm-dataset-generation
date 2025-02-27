WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Filtering for Questions only
),
TopUserPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CreationDate,
        STRING_AGG(t.TagName, ', ') AS TagList
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Tags t ON POSITION(t.TagName IN rp.Tags) > 0 -- Checking if the tag is present in the post tags
    WHERE 
        rp.Rank <= 5 -- Only take top 5 posts per user
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.ViewCount, rp.OwnerDisplayName, rp.CreationDate
),
UserStatistics AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.ViewCount > 1000 THEN 1 ELSE 0 END) AS PopularPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId IN (1, 2) -- Considering both Questions and Answers
    GROUP BY 
        u.DisplayName
)
SELECT 
    ups.OwnerDisplayName,
    ups.Title,
    ups.ViewCount,
    ups.TagList,
    us.TotalPosts,
    us.TotalAnswers,
    us.PopularPosts
FROM 
    TopUserPosts ups
JOIN 
    UserStatistics us ON ups.OwnerDisplayName = us.DisplayName
ORDER BY 
    ups.ViewCount DESC, us.TotalPosts DESC
LIMIT 10; -- Limiting to the top 10 results for benchmarking
