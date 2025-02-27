WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId -- Assuming a.ParentId refers back to their parent question
    LEFT JOIN 
        LATERAL (
            SELECT 
                unnest(string_to_array(p.Tags, '<>')) AS TagName
        ) t ON TRUE
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' AND
        p.PostTypeId = 1 -- Filtering for questions only
    GROUP BY 
        p.Id, u.DisplayName
),
MostCommented AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments
    FROM 
        Comments
    GROUP BY 
        PostId
),
TopPosts AS (
    SELECT 
        rp.Title,
        rp.Body,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        mp.TotalComments,
        rp.Tags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        MostCommented mp ON rp.PostId = mp.PostId
    WHERE 
        rp.PostRank <= 5 -- Top 5 posts per user
    ORDER BY 
        rp.Score DESC
)
SELECT 
    Title,
    Body,
    OwnerDisplayName,
    ViewCount,
    Score,
    TotalComments,
    Tags
FROM 
    TopPosts
WHERE 
    TotalComments IS NOT NULL
ORDER BY 
    TotalComments DESC, Score DESC;
This SQL query retrieves the top posts from the last year, grouped by users, that have the highest scores, along with their associated comment counts and tags. It filters for questions only and ranks the posts per user, finally presenting a ranked list of the top questions based on user engagement.
