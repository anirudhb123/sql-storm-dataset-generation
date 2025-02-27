WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersGiven,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END), 0) AS VoteCount,
        COALESCE(SUM(CASE WHEN B.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgesEarned
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON V.UserId = U.Id AND V.PostId = P.Id
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionsAsked,
        AnswersGiven,
        VoteCount,
        BadgesEarned,
        RANK() OVER (ORDER BY QuestionsAsked DESC, AnswersGiven DESC, VoteCount DESC) AS UserRank
    FROM 
        UserActivity
)
SELECT 
    UserId,
    DisplayName,
    QuestionsAsked,
    AnswersGiven,
    VoteCount,
    BadgesEarned,
    UserRank
FROM 
    TopUsers
WHERE 
    UserRank <= 10
ORDER BY 
    UserRank;

### Explanation:
1. **UserActivity CTE**: This part aggregates user activity metrics, counting the number of questions asked, answers given, votes cast (both up and down), and badges earned.
2. **TopUsers CTE**: It ranks users based on the number of questions asked, answers given, and their vote count, creating a leadership ranking.
3. **Final SELECT**: It fetches the top 10 users based on their calculated rank, ensuring that they are ordered accordingly.

This SQL query can serve as a benchmark for string processing by counting various user actions and showcasing a leaderboard, which involves complex aggregations and rank calculations within the `Users`, `Posts`, `Votes`, and `Badges` tables in a Stack Overflow-like schema.
