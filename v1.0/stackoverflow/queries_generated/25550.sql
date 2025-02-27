WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(a.Id) DESC) AS Rank,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS NewestPosts
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1 -- Join to get answers for questions
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only include questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.AnswerCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN rp.Rank <= 10 THEN 'Top 10 Questions'
        ELSE 'Other Questions'
    END AS Category,
    rp.NewestPosts
FROM 
    RankedPosts rp
WHERE 
    rp.NewestPosts <= 50 -- Get only the latest 50 posts
ORDER BY 
    rp.Rank ASC, rp.PostId DESC;

This SQL query does the following:
1. **RankedPosts CTE**: It calculates the number of answers, upvotes, and downvotes for all questions in the `Posts` table. It ranks the questions based on the number of answers and assigns each a row number based on creation date.
2. **SELECT Statement**: It fetches the post information along with the category ('Top 10 Questions' or 'Other Questions') based on their rank.
3. **WHERE Clause**: It filters the result to only display the latest 50 posts, ordered first by rank and then by post ID.
