WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(COUNT(DISTINCT C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.CreationDate IS NOT NULL), 0) AS TotalVotes,
        AVG(COALESCE(P.Score, 0)) AS AverageScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (2, 3) -- only UpMod and DownMod
    GROUP BY U.Id, U.DisplayName
),
PopularUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AnswerCount,
        CommentCount,
        TotalVotes,
        AverageScore,
        RANK() OVER (ORDER BY TotalVotes DESC) AS VoteRank,
        RANK() OVER (ORDER BY AnswerCount DESC) AS AnswerRank
    FROM UserPostStats
    HAVING AVGScore > 0 AND QuestionCount > 5
),
BannedUsers AS (
    SELECT DISTINCT UserId 
    FROM Votes
    WHERE VoteTypeId = 10 -- Assume 10 is for Deletion
),
FinalResults AS (
    SELECT 
        PU.UserId,
        PU.DisplayName,
        PU.QuestionCount,
        PU.AnswerCount,
        PU.CommentCount,
        PU.TotalVotes,
        PU.AverageScore,
        CASE 
            WHEN BU.UserId IS NOT NULL THEN 'Banned'
            ELSE 'Active' 
        END AS UserStatus
    FROM PopularUsers PU
    LEFT JOIN BannedUsers BU ON PU.UserId = BU.UserId
)
SELECT 
    UserId,
    DisplayName,
    QuestionCount,
    AnswerCount,
    CommentCount,
    TotalVotes,
    AverageScore,
    UserStatus
FROM FinalResults
WHERE UserStatus = 'Active'
ORDER BY AverageScore DESC, TotalVotes DESC;

This query performs the following tasks:

1. **UserPostStats CTE**: Calculates various statistics for users including question count, answer count, comment count, total votes, and average scores from their posts.
2. **PopularUsers CTE**: Filters users that have a positive average score and have asked more than five questions. It ranks users based on total votes and answers.
3. **BannedUsers CTE**: Identifies users who have been marked as banned based on votes (assumed that vote type 10 indicates deletion).
4. **FinalResults CTE**: Merges the popular users with the banned users to establish their status (active or banned).
5. **Final Select Statement**: Outputs the active users sorted by their average score and total votes, effectively providing a leaderboard of useful contributors who are not banned.

This query demonstrates the use of multiple CTEs, effective use of window functions, conditional aggregation, outer joins, and complex filtering based on the logic of user interactions with posts.
