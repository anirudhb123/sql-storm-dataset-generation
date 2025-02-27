WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        ROW_NUMBER() OVER(PARTITION BY U.AccountId ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerName,
        ROW_NUMBER() OVER(PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
),
PostVotes AS (
    SELECT 
        V.PostId, 
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserDisplayName,
        PH.Comment,
        PH.Text AS CloseReason,
        ROW_NUMBER() OVER(ORDER BY PH.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
)

SELECT 
    R.UserId,
    R.DisplayName,
    R.Reputation,
    COALESCE(RP.PostRank, 0) AS RecentPostRank,
    COALESCE(RP.PostId, 0) AS RecentPostId,
    COALESCE(RP.Title, 'No Recent Post') AS RecentPostTitle,
    COALESCE(RP.ViewCount, 0) AS RecentPostViewCount,
    COALESCE(PV.UpVotes, 0) AS UpVotes,
    COALESCE(PV.DownVotes, 0) AS DownVotes,
    COALESCE(CP.CloseRank, 0) AS ClosePostRank,
    COALESCE(CP.CloseReason, 'Not Closed') AS RecentCloseReason
FROM 
    UserReputation R
LEFT JOIN 
    RecentPosts RP ON R.UserId = RP.OwnerUserId AND RP.PostRank = 1
LEFT JOIN 
    PostVotes PV ON PV.PostId = COALESCE(RP.PostId, 0)
LEFT JOIN 
    ClosedPosts CP ON CP.PostId = COALESCE(RP.PostId, 0)
WHERE 
    R.Rank <= 5
ORDER BY 
    R.Reputation DESC;

### Explanation:

1. **UserReputation CTE**: This subquery ranks users with a reputation greater than 1000 based on their reputation and associates their AccountId.
   
2. **RecentPosts CTE**: It fetches posts created in the last 30 days along with the owner’s display name and assigns rank based on the creation date.

3. **PostVotes CTE**: This calculates the number of upvotes and downvotes for each post along with the total votes.

4. **ClosedPosts CTE**: It selects posts from the `PostHistory` table that have been closed, including details about the user who closed the post.

5. **Final Selection**: The main query joins all the CTEs:
   - It uses `LEFT JOIN` to ensure that users without recent posts or votes are still displayed.
   - It selects the top 5 users based on reputation, displaying their recent post details (if available), voting stats, and if any of their recent posts have been closed along with the reason.

This query effectively benchmarks performance across multiple joins, aggregate functions, and various logical conditions while also demonstrating useful window functions and CTEs for better readability and organization.
