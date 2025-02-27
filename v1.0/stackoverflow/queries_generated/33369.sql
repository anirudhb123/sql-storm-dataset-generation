WITH RecursivePosts AS (
    -- CTE to recursively find all answers for questions
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        1 AS Level
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1  -- Start with questions
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.ParentId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        rp.Level + 1
    FROM
        Posts p
    INNER JOIN
        RecursivePosts rp ON p.ParentId = rp.PostId  -- Join to get answers
    WHERE
        p.PostTypeId = 2  -- Only answers
),
AggregatedData AS (
    -- Aggregate data for performance benchmarking
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        COUNT(CASE WHEN p.Score > 0 THEN 1 END) AS UpvotedCount,
        COUNT(CASE WHEN p.Score < 0 THEN 1 END) AS DownvotedCount,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPosts,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenedPosts
    FROM 
        Posts p 
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.OwnerUserId
),
UserStats AS (
    -- Join user data to the aggregated posts
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        a.QuestionCount,
        a.AnswerCount,
        a.UpvotedCount,
        a.DownvotedCount,
        a.AvgScore,
        a.ClosedPosts,
        a.ReopenedPosts,
        RANK() OVER (ORDER BY a.AvgScore DESC) AS ScoreRank
    FROM 
        Users u
    JOIN 
        AggregatedData a ON u.Id = a.OwnerUserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.QuestionCount,
    us.AnswerCount,
    us.UpvotedCount,
    us.DownvotedCount,
    us.AvgScore,
    us.ClosedPosts,
    us.ReopenedPosts,
    us.ScoreRank,
    COALESCE(b.Name, 'No Badge') AS BadgeName
FROM 
    UserStats us
LEFT JOIN 
    Badges b ON us.UserId = b.UserId AND b.Class = 1  -- Get Gold badges
WHERE 
    us.ScoreRank <= 10  -- Top 10 users by score
ORDER BY 
    us.ScoreRank;
