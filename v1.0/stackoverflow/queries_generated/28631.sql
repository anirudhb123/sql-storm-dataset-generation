WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (2, 3) -- Count only Upvotes (2) and Downvotes (3)
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Tags, u.DisplayName
),

TagStatistics AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '> <'))::varchar[]) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only questions
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5  -- Only include tags with more than 5 questions
),

TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.OwnerDisplayName,
        pd.ViewCount,
        pd.CommentCount,
        pd.VoteCount,
        ROW_NUMBER() OVER (ORDER BY pd.ViewCount DESC) AS Rank
    FROM 
        PostDetails pd
    JOIN 
        TagStatistics ts ON pd.Tags LIKE '%' || ts.TagName || '%'
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.CommentCount,
    tp.VoteCount
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10  -- Show top 10 posts
ORDER BY 
    tp.ViewCount DESC;
