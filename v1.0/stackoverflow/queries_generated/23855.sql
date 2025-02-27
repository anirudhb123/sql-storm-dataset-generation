WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId IN (2, 5) THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS AnsweredQuestions,
        COUNT(DISTINCT CASE 
            WHEN B.Id IS NOT NULL AND B.Class = 1 THEN B.Id 
            ELSE NULL END) AS GoldBadges
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 2
    LEFT JOIN Badges B ON U.Id = B.UserId AND B.TagBased = 0
    WHERE U.Reputation > 100
    GROUP BY U.Id, U.DisplayName
),

ClosedPostStats AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS ClosedPosts,
        MAX(PH.CreationDate) AS LastClosedDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10 -- Closed Post
    GROUP BY PH.UserId
),

PostStats AS (
    SELECT
        P.Id AS PostId,
        P.OwnerUserId,
        P.CreationDate,
        P.AcceptedAnswerId,
        CHAR_LENGTH(P.Body) AS BodyLength,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 'Accepted' 
            ELSE 'Not Accepted' 
        END AS AnswerStatus,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
)

SELECT 
    U.DisplayName, 
    U.VotesCount, 
    COALESCE(CPS.ClosedPosts, 0) AS ClosedPostsCount, 
    COALESCE(CPS.LastClosedDate, 'Never Closed') AS LastClosedPostDate,
    U.AnsweredQuestions,
    U.TotalUpVotes,
    U.TotalDownVotes,
    P.BodyLength,
    P.AnswerStatus
FROM UserVoteStats U
LEFT JOIN ClosedPostStats CPS ON U.UserId = CPS.UserId
LEFT JOIN PostStats P ON U.UserId = P.OwnerUserId AND P.PostRank = 1
WHERE (U.TotalUpVotes - U.TotalDownVotes) > 10
ORDER BY U.TotalUpVotes DESC, U.GoldBadges DESC
LIMIT 10;

### Explanation:
This SQL query performs several complex operations to gather valuable insights from the Stack Overflow schema:

1. **CTEs (Common Table Expressions)**:
   - `UserVoteStats`: Gathers statistics about user votes, counting total upvotes and downvotes, the number of answered questions, and the count of gold badges.
   - `ClosedPostStats`: Calculates the number of posts closed by each user and the date of the last closed post.
   - `PostStats`: Retrieves information on posts made by users in the last year, including their acceptance status and body length.

2. **Joins**:
   - Joins `UserVoteStats` with `ClosedPostStats` to merge user statistics with their closed post data.
   - Joins the result with the `PostStats` CTE to get the most recent post details of each user.

3. **Complex Logic**:
   - A compound predicate filters users based on their vote difference, ensuring we only include those with more than ten net upvotes.

4. **Window Functions**:
   - `ROW_NUMBER()` is used in the `PostStats` CTE to rank posts by creation date per user, allowing the selection of the latest post efficiently.

5. **Case Statements**:
   - Used to determine the status of answers (whether accepted) and the last closed post description.

6. **NULL Logic**:
   - Uses `COALESCE` to handle potential NULL values that might arise if a user has no closed posts.

7. **Ordering and Limiting**:
   - Results are ordered by net upvotes and gold badge count, returning only the top 10 users.

This query showcases a mix of advanced SQL techniques while leveraging the schema effectively.
