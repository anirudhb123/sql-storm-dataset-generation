WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
QuestionStats AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS QuestionCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AverageViews,
        MAX(P.CreationDate) AS LastQuestionDate
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.OwnerUserId
),
AnswerStats AS (
    SELECT 
        P.ParentId AS QuestionId,
        COUNT(P.Id) AS AnswerCount,
        SUM(P.Score) AS AnswerScore
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 2
    GROUP BY 
        P.ParentId
),
TopQuestions AS (
    SELECT 
        Q.OwnerUserId,
        Q.QuestionCount,
        COALESCE(A.AnswerCount, 0) AS AnswerCount,
        COALESCE(A.AnswerScore, 0) AS TotalAnswerScore,
        UB.BadgeCount,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges
    FROM 
        QuestionStats Q
    LEFT JOIN 
        AnswerStats A ON Q.OwnerUserId = A.QuestionId
    LEFT JOIN 
        UserBadgeStats UB ON Q.OwnerUserId = UB.UserId
    WHERE 
        Q.QuestionCount > 0
),
FinalRanking AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY QuestionCount DESC, TotalScore DESC, TotalAnswerScore DESC) AS Rank
    FROM 
        TopQuestions
)
SELECT 
    F.OwnerUserId, 
    U.DisplayName,
    F.Rank, 
    F.QuestionCount, 
    F.AnswerCount, 
    F.TotalScore, 
    F.TotalAnswerScore,
    CASE 
        WHEN F.BadgeCount > 5 THEN 'Excellent Contributor'
        WHEN F.BadgeCount BETWEEN 1 AND 5 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributorCategory,
    CASE 
        WHEN F.LastQuestionDate IS NULL THEN 'No Questions Asked'
        ELSE 'Questions Asked'
    END AS QuestionStatus
FROM 
    FinalRanking F
JOIN 
    Users U ON F.OwnerUserId = U.Id
WHERE 
    U.Reputation > 1000 
ORDER BY 
    Rank;

### Explanation of SQL Query Constructs Used:

1. **CTEs (Common Table Expressions)**: 
   - UserBadgeStats, QuestionStats, AnswerStats, TopQuestions, and FinalRanking are used to break down the complex logic into manageable sections.

2. **Aggregations**: 
   - Multiple aggregations are performed to gather badge counts, question counts, scores, and averages.

3. **JOINs**: 
   - LEFT JOINs are used to include users even if they don't have related badges or posts.

4. **RANK() Window Function**: 
   - Ranks users based on their contributions and total scores.

5. **CASE Statements**: 
   - Used to categorize users based on their badge counts and question activity status.

6. **Filtering with Predicates**: 
   - The final selection filters users with a minimum reputation of 1000.

7. **Sorting**: 
   - The final result set is ordered by user rank.

This query is complex and illustrative of various SQL features, helping in performance benchmarking while also providing useful insights into user contributions on the Stack Overflow-like platform.
