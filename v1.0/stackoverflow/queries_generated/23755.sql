WITH UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS RankReputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        CASE 
            WHEN p.AcceptedAnswerId IS NULL THEN 'No Accepted Answer' 
            ELSE 'Has Accepted Answer' 
        END AS AnswerStatus,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    AND p.PostTypeId = 1 
),
UserPostAnalytics AS (
    SELECT
        ur.UserId,
        ur.DisplayName,
        COUNT(DISTINCT pp.PostId) AS QuestionsAsked,
        SUM(CASE WHEN pp.AcceptedAnswerId <> -1 THEN 1 ELSE 0 END) AS QuestionsAnswered,
        AVG(pp.Score) AS AvgQuestionScore
    FROM UserReputation ur
    LEFT JOIN TopPosts pp ON ur.UserId = pp.AcceptedAnswerId
    GROUP BY ur.UserId, ur.DisplayName
),
RankedAnalytics AS (
    SELECT
        upa.UserId,
        upa.DisplayName,
        upa.QuestionsAsked,
        upa.QuestionsAnswered,
        upa.AvgQuestionScore,
        RANK() OVER (ORDER BY upa.AvgQuestionScore DESC, upa.QuestionsAsked DESC) AS RankByScore
    FROM UserPostAnalytics upa
),
FinalReport AS (
    SELECT 
        ra.UserId,
        ra.DisplayName,
        ra.QuestionsAsked,
        ra.QuestionsAnswered,
        ra.AvgQuestionScore,
        CASE 
            WHEN ra.QuestionsAnswered > 0 THEN 'Active Responder'
            ELSE 'Inactive Responder'
        END AS ResponseCategory,
        CASE 
            WHEN rb.RankReputation <= 10 THEN 'Top User'
            ELSE 'Regular User'
        END AS UserCategory
    FROM RankedAnalytics ra
    LEFT JOIN UserReputation rb ON ra.UserId = rb.UserId
)
SELECT 
    fr.UserId,
    fr.DisplayName,
    fr.QuestionsAsked,
    fr.QuestionsAnswered,
    fr.AvgQuestionScore,
    fr.ResponseCategory,
    fr.UserCategory
FROM FinalReport fr
WHERE fr.QuestionsAsked > 0
AND fr.AvgQuestionScore IS NOT NULL
ORDER BY fr.AvgQuestionScore DESC, fr.QuestionsAsked DESC
LIMIT 100;
This SQL query demonstrates a multi-step process utilizing Common Table Expressions (CTEs) to aggregate data from multiple tables, including ranking users based on reputation and their activity with questions (posts) in the last 30 days. It incorporates outer joins, window functions, complex predicates, and string case expressions to categorize users based on their engagement in the StackOverflow schema.
