WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS Rank,
        (
            SELECT 
                COUNT(*)
            FROM 
                Posts p
            WHERE 
                p.OwnerUserId = u.Id 
                AND p.PostTypeId = 1
                AND p.CreationDate >= '2023-01-01'
        ) AS RecentQuestionsCount
    FROM 
        Users u
),
AnswerStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalAnswers,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 2 
    GROUP BY 
        p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Gold badges only
    GROUP BY 
        b.UserId
),
PostsSummary AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    ru.Rank,
    COALESCE(ps.TotalPosts, 0) AS TotalPosts,
    COALESCE(ps.TotalViews, 0) AS TotalViews,
    COALESCE(ps.TotalScore, 0) AS TotalScore,
    COALESCE(as.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(as.AcceptedAnswers, 0) AS AcceptedAnswers,
    COALESCE(ub.Badges, 'No Gold Badges') AS GoldBadges,
    ru.RecentQuestionsCount
FROM 
    RankedUsers ru
LEFT JOIN 
    PostsSummary ps ON ps.OwnerUserId = ru.UserId
LEFT JOIN 
    AnswerStats as ON as.OwnerUserId = ru.UserId
LEFT JOIN 
    UserBadges ub ON ub.UserId = ru.UserId
WHERE 
    ru.Rank <= 10 -- Top 10 users by reputation
    AND ru.RecentQuestionsCount > 5 -- Users with more than 5 recent questions
ORDER BY 
    ru.Rank;

This query performs the following complex operations:
1. **Common Table Expressions (CTEs)** to break down the calculations and give clarity:
   - `RankedUsers`: Ranks users by reputation and counts recent questions.
   - `AnswerStats`: Aggregates the number of answers per user and counts accepted answers.
   - `UserBadges`: Concatenates the names of gold badges per user.
   - `PostsSummary`: Sums up the views and scores for each user's posts.

2. **Correlated subquery** to count recent questions for each user.

3. **NULL handling** using `COALESCE`.

4. **Lateral join** semantics through CTEs to bring rich user insights, maintaining the complexity and performance expectations.

5. **Complicated filtering conditions** to target specific users: top reputation, recent question activity, etc.

This query aims to offer a performance benchmark by aggregating user data with multiple joins, rationalized calculations, and conditions that check for substantive contributions from users in a community-like environment.
