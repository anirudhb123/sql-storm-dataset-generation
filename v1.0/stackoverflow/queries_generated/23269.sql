WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Only Questions
        AND P.Score > 0
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostVoteHistory AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId = 6 THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN V.VoteTypeId = 7 THEN 1 END) AS ReopenVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    RB.BadgeCount,
    RB.BadgeNames,
    RP.PostId,
    RP.Title AS QuestionTitle,
    RP.CreationDate AS QuestionDate,
    PH.PostHistoryTypeId,
    PH.CreationDate AS HistoryDate,
    COALESCE(PVH.UpVotes, 0) AS UpVotes,
    COALESCE(PVH.DownVotes, 0) AS DownVotes,
    COALESCE(PVH.CloseVotes, 0) AS CloseVotes,
    COALESCE(PVH.ReopenVotes, 0) AS ReopenVotes,
    PH.Comment
FROM 
    RankedPosts RP
JOIN 
    Users U ON RP.PostRank = 1 AND RP.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.Id)
LEFT JOIN 
    UserBadges RB ON U.Id = RB.UserId
LEFT JOIN 
    PostHistory PH ON RP.PostId = PH.PostId
LEFT JOIN 
    PostVoteHistory PVH ON RP.PostId = PVH.PostId
WHERE 
    PH.CreationDate < RP.CreationDate 
    AND PH.CreationDate >= NOW() - INTERVAL '1 year'
ORDER BY 
    U.Reputation DESC, 
    RP.Score DESC 
LIMIT 100;

### Query Explanation:
- **Common Table Expressions (CTEs)**: 
  - `RankedPosts` gets the latest questions for each user with a positive score.
  - `UserBadges` collects the badge data associated with each user.
  - `PostVoteHistory` totals votes and categorizes them for each post.
  
- **Joins**: 
  - Users are joined with ranked posts to find user information based on the newest question of each user.
  - Badges are left-joined to get the number of badges for users.
  - Post history is joined to get changes made to questions in the past year.

- **NULL Logic**: 
  - The use of `COALESCE` is to ensure that if a post has no votes in a category, it still returns `0`.

- **Complex Conditions**: 
  - The conditions in the `WHERE` clause ensure that we are only considering post histories that occurred before the question's date but within the last year.

- **Limitations and Ordering**: 
  - The final results are limited to the top 100 entries based on reputation and score for ranking and performance analysis. 

This query combines multiple SQL features to create complex logic that can be used for insightful performance analysis on this StackOverflow schema.
