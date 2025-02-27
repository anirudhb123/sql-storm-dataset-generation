WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(pv.VoteCount, 0) AS VoteCount,
        pb.AverageScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(pv.VoteCount, 0) DESC, pb.AverageScore DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        WHERE 
            VoteTypeId IN (2, 3) -- considering only upvotes and downvotes
        GROUP BY 
            PostId
    ) pv ON p.Id = pv.PostId
    LEFT JOIN (
        SELECT 
            ParentId,
            AVG(Score) AS AverageScore
        FROM 
            Posts
        WHERE 
            PostTypeId = 2 -- answers
        GROUP BY 
            ParentId
    ) pb ON p.Id = pb.ParentId
), CommentsCount AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
), ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        DENSE_RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
), FinalRanking AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.VoteCount,
        cc.CommentCount,
        COALESCE(cp.CloseRank, 0) AS IsClosed
    FROM 
        RankedPosts rp
    LEFT JOIN 
        CommentsCount cc ON rp.PostId = cc.PostId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.VoteCount,
    fr.CommentCount,
    CASE 
        WHEN fr.IsClosed > 0 THEN 'Closed'
        ELSE 'Open' 
    END AS PostStatus
FROM 
    FinalRanking fr
WHERE 
    fr.Rank <= 10 -- Top 10 ranks
ORDER BY 
    fr.VoteCount DESC, fr.CreationDate DESC;
This query generates a comprehensive report on the top-ranking posts in a forum-like application. It includes:
- A common table expression (CTE) `RankedPosts` to rank posts based on their vote counts and average scores for answers.
- Another CTE `CommentsCount` to calculate the number of comments associated with each post.
- A CTE `ClosedPosts` to identify closed posts along with the user and the comment at the time of closure.
- Finally, `FinalRanking` brings all these details together to produce a final output that indicates each post's status (open or closed) along with its ranking metrics. The output is sorted by the number of votes and creation date, showing the top 10 posts based on provided criteria.
