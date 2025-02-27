WITH RECURSIVE UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Name AS BadgeName,
        B.Class,
        B.Date,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
),
TopQuestions AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        P.Score,
        P.AnswerCount,
        P.CreationDate,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVotes,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.AcceptedAnswerId AND V.VoteTypeId = 2) 
            ELSE 0 
        END AS AcceptedAnswerUpVotes
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 AND P.Score > 0
),
Ranking AS (
    SELECT 
        Q.QuestionId,
        Q.Title,
        Q.AnswerCount,
        Q.UpVotes,
        Q.DownVotes,
        (Q.UpVotes - Q.DownVotes) AS VoteBalance,
        RANK() OVER (ORDER BY Q.Score DESC, Q.CreationDate DESC) AS Rank
    FROM 
        TopQuestions Q
)
SELECT 
    R.Rank,
    R.Title,
    R.AnswerCount,
    R.VoteBalance,
    UB.DisplayName,
    UB.BadgeName
FROM 
    Ranking R
LEFT JOIN 
    UserBadges UB ON R.Rank = 1 AND UB.BadgeRank = 1
WHERE 
    R.Rank <= 10
ORDER BY 
    R.Rank;

-- 1. The CTE UserBadges fetches user badges and assigns a rank to each badge per user.
-- 2. TopQuestions retrieves essential details about top questions including upvote/downvote counts using subqueries.
-- 3. Ranking assigns a rank to the questions based on their score and creation date.
-- 4. Finally, we select the top 10 questions along with the badge holder's name and badge for better insight.
