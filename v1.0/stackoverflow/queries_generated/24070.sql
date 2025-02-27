WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score > (SELECT AVG(Score) FROM Posts WHERE CreationDate >= CURRENT_DATE - INTERVAL '1 year')
)
SELECT 
    up.DisplayName AS UserName,
    up.Reputation,
    vp.VoteCount AS TotalVotes,
    COALESCE(ps.RankRowNumber, 0) AS RankPosition,
    CASE 
        WHEN ps.RankRowNumber IS NOT NULL AND ps.RankRowNumber <= 5 THEN 'Top 5 Posts'
        ELSE 'Other Posts'
    END AS PostCategory
FROM 
    Users up
LEFT JOIN 
    (
        SELECT 
            v.UserId,
            COUNT(*) AS VoteCount
        FROM 
            Votes v
        JOIN 
            RankedPosts rp ON v.PostId = rp.Id
        GROUP BY 
            v.UserId
    ) vp ON up.Id = vp.UserId
LEFT JOIN 
    (
        SELECT 
            rp.Id,
            rp.PostRank AS RankRowNumber
        FROM 
            RankedPosts rp
    ) ps ON up.Id = ps.Id
WHERE 
    up.Reputation > 1000 OR up.Likes IS NULL
ORDER BY 
    up.Reputation DESC, 
    TotalVotes DESC
LIMIT 10;

-- Additionally, fetch comments related to the top posts
WITH TopPostComments AS (
    SELECT 
        c.Id AS CommentId,
        c.PostId,
        c.Text AS CommentText,
        c.CreationDate AS CommentDate,
        u.DisplayName AS CommenterName
    FROM 
        Comments c
    JOIN 
        Posts p ON c.PostId = p.Id
    JOIN 
        Users u ON c.UserId = u.Id
    WHERE 
        p.Id IN (SELECT Id FROM RankedPosts WHERE PostRank <= 5)
)
SELECT 
    tpc.CommentId,
    tpc.CommentText,
    tpc.CommentDate,
    tpc.CommenterName,
    CASE 
        WHEN tpc.PostId IS NULL THEN 'No linked Post'
        ELSE 'Comment associated'
    END AS LinkStatus
FROM 
    TopPostComments tpc;

This SQL query performs several complex operations:

1. **RankedPosts CTE**: Identifies posts made in the last year that scored above the average, assigning ranks based on the score.
  
2. **UserVote Summary**: Aggregates total votes per user, showcasing users with over 1000 reputations or no likes.

3. **Post Categorization**: Categorizes whether the user posted in the top 5 posts or not.

4. **Left joins**: Use of outer joins to ensure users without votes are also included.

5. **TopPostComments CTE**: Gathers comments linked to the top posts and links them back to users.

6. **CASE statement**: An intricate case logic to check if comments are related to posts, demonstrating NULL handling and logical checks.

7. **Final selection**: Generates a final output after all join conditions, maintaining a coherent and accessible result set while also ordering by user reputation and vote count.
