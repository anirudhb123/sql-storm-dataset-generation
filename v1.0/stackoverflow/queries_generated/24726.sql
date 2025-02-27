WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS TotalUpvotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS TotalDownvotes,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(v.VoteTypeId = 2), 0) - COALESCE(SUM(v.VoteTypeId = 3), 0) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostHistoryStats AS (
    SELECT
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT CONCAT(pht.Name, ': ', ph.Comment), '; ') AS EditTypes 
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
QuestionWithHighestViews AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.TotalPosts,
    ua.TotalQuestions,
    ua.TotalAnswers,
    ua.TotalUpvotes - ua.TotalDownvotes AS VoteBalance,
    phs.EditCount AS TotalEdits,
    phs.LastEditDate,
    phs.EditTypes,
    qh.ViewRank,
    qh.Title AS MostViewedQuestion,
    qh.ViewCount AS HighestViews
FROM 
    UserActivity ua
LEFT JOIN 
    PostHistoryStats phs ON phs.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ua.UserId)
LEFT JOIN 
    QuestionWithHighestViews qh ON (qh.ViewRank = 1 AND ua.TotalQuestions > 0)
WHERE 
    ua.Reputation > 100 
    AND (ua.TotalPosts > 5 OR ua.TotalAnswers > 10)
ORDER BY 
    ua.UserRank, ua.DisplayName;
