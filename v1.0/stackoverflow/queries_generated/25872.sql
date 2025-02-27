WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '><')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.ViewCount, p.Score
),

TopUserPosts AS (
    SELECT 
        OwnerDisplayName,
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        CommentCount,
        Tags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 -- Top 5 posts by score for each user
)

SELECT 
    OwnerDisplayName,
    COUNT(PostId) AS PostCount,
    SUM(ViewCount) AS TotalViews,
    AVG(Score) AS AverageScore,
    ARRAY_AGG(PostId) AS PostIds,
    STRING_AGG(DISTINCT unnest(Tags), ', ') AS UniqueTags
FROM 
    TopUserPosts
GROUP BY 
    OwnerDisplayName
ORDER BY 
    PostCount DESC, TotalViews DESC
LIMIT 10; -- Top 10 users with the most posts
