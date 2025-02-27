WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesReceived,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesReceived,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        AVG(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS AveragePostScore,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotesReceived,
        DownVotesReceived,
        TotalPosts,
        AveragePostScore,
        RANK() OVER (ORDER BY UpVotesReceived DESC) AS UpVoteRank
    FROM 
        UserVoteStats
),
HighScorePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.Score IS NOT NULL AND P.Score >= 10
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        PH.UserDisplayName,
        PH.Comment,
        PH.Text,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RecentActivity
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12) -- focusing on post close, reopen, and delete events
),
CombinedResults AS (
    SELECT 
        U.DisplayName AS UserDisplayName,
        UP.UpVotesReceived,
        UP.DownVotesReceived,
        HP.Title AS HighScorePost,
        HP.Score AS PostScore,
        PH.RecentActivity,
        PH.Comment AS RecentComment,
        PH.CreationDate AS RecentActivityDate
    FROM 
        TopUsers UP
    LEFT JOIN 
        HighScorePosts HP ON UP.UserId = HP.OwnerUserId
    LEFT JOIN 
        PostHistoryDetails PH ON HP.PostId = PH.PostId AND PH.RecentActivity <= 5
)
SELECT 
    UserDisplayName,
    UpVotesReceived,
    DownVotesReceived,
    COUNT(HighScorePost) AS TotalHighScorePosts,
    MAX(PostScore) AS MaxPostScore,
    STRING_AGG(DISTINCT RecentComment, '; ') AS RecentComments,
    COUNT(CASE WHEN RecentActivity IS NOT NULL THEN 1 END) AS TotalRecentActivities
FROM 
    CombinedResults
GROUP BY 
    UserDisplayName, UpVotesReceived, DownVotesReceived
HAVING 
    COUNT(HighScorePost) >= 2 
ORDER BY 
    UpVotesReceived DESC, TotalHighScorePosts DESC;

### Explanation of the Query
1. **UserVoteStats CTE**: This calculates statistics for each user, including the number of upvotes and downvotes received, total posts, average post score, and number of questions and answers authored.
  
2. **TopUsers CTE**: Ranks users according to the number of upvotes they’ve received.

3. **HighScorePosts CTE**: Retrieves posts that have a score of at least 10, ranking them similarly.

4. **PostHistoryDetails CTE**: Focuses on specific events in post history (closing, reopening, and deletion) to capture recent activity.

5. **CombinedResults CTE**: Joins the user statistics, high-score posts, and recent activity for detailed per-user output.

6. **Final SELECT statement**: Groups results by user for presentation, including conditions for having a minimum number of high-score posts, resulting in a rich output dataset ready for performance benchmarking.

The structure is designed to test various SQL constructs like CTEs, window functions, outer joins, complex aggregations, and filtering with predicates to push the limits of SQL performance.
