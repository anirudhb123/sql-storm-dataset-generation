WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Score,
        p.Title,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Score,
        p.Title,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),

PostStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        COALESCE(SUM(v.VoteTypeId IN (2)), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId IN (3)), 0) AS DownVotes,
        PC.Level AS PostLevel,
        RANK() OVER (PARTITION BY COALESCE(p.ParentId, 0) ORDER BY p.CreationDate DESC) AS RecentRanking
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        RecursivePostHierarchy PC ON p.Id = PC.PostId
    GROUP BY 
        p.Id, p.Title, p.AnswerCount, p.CommentCount, p.CreationDate, PC.Level
),

RecentPosts AS (
    SELECT 
        ps.Title,
        ps.AnswerCount,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.PostLevel,
        ps.RecentRanking,
        u.DisplayName,
        CASE 
            WHEN ps.PostLevel > 0 THEN 'Response'
            ELSE 'Question'
        END AS PostType
    FROM 
        PostStatistics ps
    JOIN 
        Users u ON ps.Id = u.Id
    WHERE 
        ps.RecentRanking = 1
        AND ps.CreationDate >= NOW() - INTERVAL '30 days'
)

SELECT 
    rp.PostType,
    rp.Title,
    rp.AnswerCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.DisplayName,
    COALESCE(NULLIF(rp.AnswerCount, 0), 1) AS AnswerCountAdjusted,
    COALESCE(NULLIF(rp.CommentCount, 0), 1) AS CommentCountAdjusted,
    (rp.UpVotes::float / NULLIF(rp.DownVotes, 0)) AS VoteRatio
FROM 
    RecentPosts rp
WHERE 
    rp.UpVotes > 0
ORDER BY 
    VoteRatio DESC
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
This query does the following:
- It defines a recursive CTE (`RecursivePostHierarchy`) to build a hierarchy of posts and their relationships, especially focusing on parent-child relationships among posts.
- Another CTE (`PostStatistics`) aggregates statistics about each post, including votes, answer counts, and the level of the post in the hierarchy.
- The final selection from `RecentPosts` filters those posts created in the last 30 days, reflecting recent activity, and calculates an adjusted count for answers and comments — ensuring at least a value of 1 to avoid division by zero errors.
- It orders the result set based on the calculated vote ratio while ensuring only posts with upvotes are included.
- It limits the output to the top 10 posts with the highest vote ratios.
