WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
HighlyCommentedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    GROUP BY 
        p.Id, p.Title
    HAVING 
        COUNT(c.Id) > 10
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        CommentCount,
        Upvotes,
        Downvotes,
        AverageReputation,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStatistics
)
SELECT DISTINCT
    tt.TagName,
    tt.PostCount,
    tt.CommentCount,
    tt.Upvotes,
    tt.Downvotes,
    tt.AverageReputation,
    hp.Title AS HighlyCommentedPostTitle,
    hp.CommentCount AS HighlyCommentedPostCount
FROM 
    TopTags tt
LEFT JOIN 
    HighlyCommentedPosts hp ON tt.TagName IN (
        SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>')) AS tag
        FROM Posts p WHERE p.Tags IS NOT NULL
    )
WHERE 
    tt.Rank <= 10
ORDER BY 
    tt.PostCount DESC, tt.AverageReputation DESC;
