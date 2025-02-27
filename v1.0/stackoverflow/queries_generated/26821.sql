WITH PostTagStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ARRAY_AGG(DISTINCT TRIM(BOTH '>' FROM unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')))) AS Tags,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT v.UserId) AS UniqueVoters
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  -- Upvotes and downvotes
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id, p.Title
),
TagPopularity AS (
    SELECT 
        tag AS TagName,
        COUNT(*) AS TotalPosts
    FROM 
        PostTagStatistics,
        unnest(Tags) AS tag
    GROUP BY 
        tag
    ORDER BY 
        TotalPosts DESC
    LIMIT 10
),
PostDetails AS (
    SELECT 
        pts.PostId,
        pts.Title,
        pts.CommentCount,
        pts.TotalBounty,
        ts.TagName
    FROM 
        PostTagStatistics pts
    JOIN 
        TagPopularity ts ON ts.TagName = ANY(pts.Tags)
)
SELECT 
    pd.Title,
    pd.CommentCount,
    pd.TotalBounty,
    STRING_AGG(DISTINCT pd.TagName, ', ') AS Tags
FROM 
    PostDetails pd
GROUP BY 
    pd.Title, pd.CommentCount, pd.TotalBounty
ORDER BY 
    pd.TotalBounty DESC, pd.CommentCount DESC
LIMIT 20;

This query benchmarks string processing by first extracting tag statistics from the `Posts` table, utilizing string manipulation functions to aggregate and clean tag data. It then calculates popularity of the tags by counting the posts associated with each tag. Finally, it joins this data back to `PostDetails`, displaying the top 20 posts by total bounty and comment count while listing their associated tags in a formatted string.
