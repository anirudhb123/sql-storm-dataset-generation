WITH RecursivePosts AS (
    -- Common Table Expression (CTE) to get all posts recursively for a specific user
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.OwnerUserId = 1  -- Replace with a specific user ID

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN RecursivePosts rp ON p.ParentId = rp.Id
),
PostStats AS (
    -- CTE to gather post statistics including comment counts and the max score of answers
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT MAX(Score) FROM Posts a WHERE a.ParentId = p.Id) AS MaxAnswerScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only for Questions
),
AggregatedData AS (
    -- Aggregate data to Group by Owner and Count badges
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        AVG(
            CASE 
                WHEN ps.Score IS NULL THEN 0
                ELSE ps.Score
            END
        ) AS AvgPostScore,
        COUNT(DISTINCT ps.Id) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ad.UserId,
    ad.DisplayName,
    ad.BadgeCount,
    ad.AvgPostScore,
    ad.QuestionCount,
    rp.Id AS RecursivePostId,
    rp.Title AS RecursivePostTitle,
    rp.CreationDate AS RecursivePostDate,
    rp.Score AS RecursivePostScore,
    COUNT(DISTINCT c.Id) AS TotalComments
FROM 
    AggregatedData ad
LEFT JOIN RecursivePosts rp ON ad.UserId = rp.OwnerUserId
LEFT JOIN Comments c ON rp.Id = c.PostId
GROUP BY 
    ad.UserId, ad.DisplayName, ad.BadgeCount, ad.AvgPostScore, ad.QuestionCount, rp.Id, 
    rp.Title, rp.CreationDate, rp.Score
ORDER BY 
    ad.QuestionCount DESC, ad.AvgPostScore DESC;
