WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Start with top-level posts

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),

PostScores AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(v.FavoriteCount, 0) AS FavoriteCount,
        (p.Score + COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0)) AS TotalScore
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
            SUM(CASE WHEN VoteTypeId = 5 THEN 1 ELSE 0 END) AS FavoriteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId 
),

TopPosts AS (
    SELECT 
        p.PostId,
        p.Title,
        p.Score,
        ps.TotalScore,
        ROW_NUMBER() OVER (ORDER BY ps.TotalScore DESC) AS Rank
    FROM 
        PostScores ps
    INNER JOIN 
        PostHierarchy p ON ps.PostId = p.PostId
    WHERE 
        p.Level = 0  -- Only consider top-level posts
)

SELECT 
    tp.Title,
    tp.Score,
    tp.TotalScore,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN tp.TotalScore >= 0 THEN 'Positive'
        ELSE 'Negative'
    END AS Score_Category 
FROM 
    TopPosts tp
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    WHERE 
        Class = 1  -- Gold badges
    GROUP BY 
        UserId
) b ON tp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = b.UserId)
WHERE 
    tp.Rank <= 10  -- Top 10 posts
ORDER BY 
    tp.TotalScore DESC;

This query does the following:

1. Creates a recursive CTE to build a hierarchy of posts (top-level and their children).
2. Calculates a scoring system combining post score, upvotes, downvotes, and favorite counts using a LEFT JOIN with an aggregated votes table.
3. Selects the top-level posts and ranks them based on the computed total score.
4. Joins with the Badges table to get the count of gold badges for each post owner.
5. Outputs the top 10 ranked posts along with their score, badge count, and a simple categorization based on their total score.
