WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- Filtering for Questions
    GROUP BY 
        p.Id
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(p.AnswerCount) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Last year
    GROUP BY 
        u.Id 
    HAVING 
        COUNT(p.Id) > 10 -- Users with more than 10 questions
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        ph.UserId,
        ph.CreationDate AS ActivityDate,
        p.Title,
        ph.PostHistoryTypeId,
        ph.Comment,
        DENSE_RANK() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS ActivityRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Close, Reopen, Delete actions
)

SELECT 
    r.PostId, 
    r.Title, 
    r.Body,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.Tags,
    au.DisplayName AS ActiveUser,
    au.QuestionCount,
    au.TotalAnswers,
    au.TotalScore,
    au.TotalViews,
    ra.ActivityDate,
    ra.PostHistoryTypeId,
    ra.Comment 
FROM 
    RankedPosts r
LEFT JOIN 
    MostActiveUsers au ON r.RN = 1 -- Taking the most recent post of active users
LEFT JOIN 
    RecentActivity ra ON r.PostId = ra.PostId AND ra.ActivityRank = 1
WHERE 
    r.RN <= 5 -- Taking top 5 most recent questions per user
ORDER BY 
    r.CreationDate DESC, 
    au.TotalViews DESC
LIMIT 100; -- Limiting result set to 100 for performance benchmarking
