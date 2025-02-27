WITH TagStats AS (
    SELECT 
        t.TagName,
        p.PostTypeId,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        MAX(p.CreationDate) AS LastPosted,
        ARRAY_AGG(DISTINCT u.DisplayName ORDER BY u.Reputation DESC) AS TopUsers
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId IN (1, 2) -- Considering only Questions and Answers
    GROUP BY 
        t.TagName, p.PostTypeId
),
TagRanking AS (
    SELECT 
        TagName,
        PostCount,
        CommentCount,
        VoteCount,
        LastPosted,
        TopUsers,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStats
)
SELECT 
    TagName,
    PostCount,
    CommentCount,
    VoteCount,
    LastPosted,
    TopUsers,
    TagRank
FROM 
    TagRanking
WHERE 
    TagRank <= 10 -- Top 10 tags by count of posts
ORDER BY 
    PostCount DESC;

This query analyzes tags associated with questions and answers, capturing information such as post counts, comment counts, vote counts, and the most active users for each tag. It ranks the tags based on post counts and returns the top 10 performing tags along with their associated metrics.
