WITH UserScoreCTE AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        (U.UpVotes - U.DownVotes) AS NetVotes,
        U.Views,
        COALESCE(DATE_PART('epoch', MAX(P.CreationDate))::int, 0) AS LastActiveEpoch,
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
        LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
),
RecentPostsCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 'Accepted' 
            ELSE 'Not Accepted' 
        END AS AnswerStatus,
        U.DisplayName AS OwnerName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM 
        Posts P
        LEFT JOIN Users U ON P.OwnerUserId = U.Id
        LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY P.Id, U.DisplayName
),
PostHistoryCTE AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        MAX(PH.CreationDate) AS LastClosedDate
    FROM 
        PostHistory PH
    GROUP BY PH.PostId
)

SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.NetVotes,
    US.Views,
    RPT.PostId,
    RPT.Title,
    RPT.CreationDate,
    RPT.ViewCount,
    RPT.Score,
    RPT.AnswerStatus,
    RPT.OwnerName,
    COALESCE(PH.CloseCount, 0) AS TotalCloseCount,
    PH.LastClosedDate,
    RPT.CommentCount,
    CASE 
        WHEN PH.LastClosedDate IS NOT NULL AND (RPT.CreationDate < PH.LastClosedDate) THEN 'Closed Before'
        ELSE 'Active or Open'
    END AS PostStatus
FROM 
    UserScoreCTE US
    LEFT JOIN RecentPostsCTE RPT ON US.UserId = RPT.OwnerName
    LEFT JOIN PostHistoryCTE PH ON RPT.PostId = PH.PostId
WHERE 
    US.Reputation > 100 -- Select users with reputation over 100
ORDER BY 
    US.Reputation DESC, 
    RPT.Score DESC -- Ordering by reputation and post score
LIMIT 50;

### Explanation of Query Components:

1. **Common Table Expressions (CTEs)**:
   - **UserScoreCTE**: Calculates user scores, including net votes, total posts, and last active date.
   - **RecentPostsCTE**: Gathers recent posts created within the last 30 days per user, their details, and comment counts.
   - **PostHistoryCTE**: Counts the number of times posts have been closed and caches the date of the last closure.

2. **Main Query**:
   - Joins these CTEs to gather user and post information.
   - Filters users by a reputation greater than 100.
   - Uses `COALESCE` to handle potential `NULL` values for count of closes.
   - Incorporates a case statement to define post status based on the closure dates.

3. **Ordering & Limiting**:
   - The final result set is ordered by reputation and post score, limiting it to the top 50 results. 

### Constructs Used:
- CTEs, outer joins, aggregated calculations, conditional logic, and filtering using `WHERE`, `ORDER BY`, and `LIMIT`.
