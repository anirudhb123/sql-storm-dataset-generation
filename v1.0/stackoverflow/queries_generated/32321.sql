WITH RecursivePostTree AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.Score,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.Score,
        p.CreationDate,
        pt.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostTree pt ON p.ParentId = pt.PostId
),
PostEngagement AS (
    SELECT 
        pt.PostId,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(b.Class) AS BadgePoints
    FROM 
        RecursivePostTree pt
    LEFT JOIN 
        Comments c ON pt.PostId = c.PostId
    LEFT JOIN 
        Votes v ON pt.PostId = v.PostId
    LEFT JOIN 
        Badges b ON v.UserId = b.UserId
    GROUP BY 
        pt.PostId
),
TopPosts AS (
    SELECT 
        pe.PostId,
        pe.TotalComments,
        pe.Upvotes,
        pe.Downvotes,
        (pe.Upvotes - pe.Downvotes) AS NetVotes,
        COALESCE(MAX(u.Reputation), 0) AS HighestReputationUser
    FROM 
        PostEngagement pe
    LEFT JOIN 
        Users u ON pe.PostId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = pe.PostId)
    GROUP BY 
        pe.PostId
),
RankedPosts AS (
    SELECT 
        tp.PostId,
        tp.TotalComments,
        tp.Upvotes,
        tp.Downvotes,
        tp.NetVotes,
        tp.HighestReputationUser,
        ROW_NUMBER() OVER (ORDER BY tp.NetVotes DESC, tp.TotalComments DESC) AS Rank
    FROM 
        TopPosts tp
)
SELECT 
    rp.PostId,
    rp.TotalComments,
    rp.Upvotes,
    rp.Downvotes,
    rp.NetVotes,
    rp.Rank,
    CASE 
        WHEN rp.HighestReputationUser > 1000 THEN 'High Reputation User Participation'
        WHEN rp.HighestReputationUser BETWEEN 500 AND 1000 THEN 'Moderate Reputation User Participation'
        ELSE 'Low or No Reputation User Participation'
    END AS UserParticipationLevel
FROM 
    RankedPosts rp
WHERE 
    rp.NetVotes > 0
ORDER BY 
    rp.Rank;

This SQL query performs several advanced operations:

1. **Recursive CTE**: `RecursivePostTree` builds a hierarchy of posts, capturing nests of questions and answers.
2. **Post Engagement CTE**: `PostEngagement` aggregates data on comments, upvotes, downvotes, and badge points for each post.
3. **Top Posts**: Calculates net votes and identifies the highest reputation user associated with each post.
4. **Ranking**: Ranks posts based on net votes and total comments.
5. **Final Output**: Selects relevant fields from the ranks, categorizing the user participation level based on reputation scores.

The query combines multiple SQL constructs, including CTEs, window functions, conditional expressions, and aggregation.
