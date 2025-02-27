WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),

FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        Upvotes,
        Downvotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)

SELECT 
    f.PostId,
    f.Title,
    f.Body,
    f.CreationDate,
    f.OwnerDisplayName,
    f.CommentCount,
    f.Upvotes,
    f.Downvotes,
    CASE 
        WHEN f.Upvotes > f.Downvotes THEN 'Positive'
        WHEN f.Downvotes > f.Upvotes THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    (SELECT STRING_AGG(TagName, ', ') 
     FROM Tags t 
     WHERE t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int))
     AND p.Id = f.PostId) AS PostTags
FROM 
    FilteredPosts f
INNER JOIN 
    Posts p ON f.PostId = p.Id
ORDER BY 
    f.CreationDate DESC;
