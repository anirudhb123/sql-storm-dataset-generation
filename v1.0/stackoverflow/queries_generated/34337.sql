WITH Recursive_Posts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AcceptedAnswerId,
        1 AS Level 
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions only

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AcceptedAnswerId,
        rp.Level + 1 
    FROM 
        Posts p
    JOIN 
        Recursive_Posts rp ON p.ParentId = rp.PostId
    WHERE 
        p.PostTypeId = 2 -- Answers only
),

Aggregated_Scores AS (
    SELECT 
        rp.PostId,
        SUM(rp.Score) AS TotalScore,
        COUNT(DISTINCT rp.PostId) AS AnswerCount,
        MAX(rp.CreationDate) AS LatestActivity
    FROM 
        Recursive_Posts rp
    GROUP BY 
        rp.PostId
),

Popular_Users AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(v.BountyAmount) > 0
    ORDER BY 
        TotalBounty DESC
    LIMIT 10
)

SELECT 
    p.Id AS PostId,
    p.Title,
    a.TotalScore AS Score,
    a.AnswerCount,
    u.DisplayName AS Owner,
    u.Reputation,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    PERCENT_RANK() OVER (ORDER BY a.TotalScore DESC) AS ScoreRank
FROM 
    Posts p
JOIN 
    Aggregated_Scores a ON p.Id = a.PostId
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    WHERE 
        Date > NOW() - INTERVAL '1 year'
    GROUP BY 
        UserId
) b ON u.Id = b.UserId
WHERE 
    p.Score IS NOT NULL 
    AND p.CreationDate < NOW() - INTERVAL '30 days'
ORDER BY 
    ScoreRank, Score DESC;

-- Bonus: Retrieve details for the most popular users who have answered these questions
WITH User_Info AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        COUNT(DISTINCT a.PostId) AS AnswerCount
    FROM 
        Popular_Users up
    JOIN 
        Posts a ON up.UserId = a.OwnerUserId
    LEFT JOIN 
        Votes v ON a.Id = v.PostId
    WHERE 
        a.PostTypeId = 2 -- only Answer posts
    GROUP BY 
        up.UserId, up.DisplayName
)
SELECT 
    *
FROM 
    User_Info
ORDER BY 
    TotalUpvotes DESC;
