WITH UserVoteStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        AVG(UPPER(SUBSTRING(P.Body, 1, 100))) AS AvgCharsInBody
    FROM
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON V.UserId = U.Id AND V.PostId = P.Id
    WHERE
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
PostClosureStats AS (
    SELECT 
        P.Id AS PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(DISTINCT PH.UserId) AS UsersInvolved
    FROM
        Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE
        P.Score < 0
    GROUP BY 
        P.Id
),
TopClosedPosts AS (
    SELECT 
        PCS.PostId,
        PCS.CloseCount,
        PCS.ReopenCount,
        P.Title,
        P.CreationDate,
        ROW_NUMBER() OVER (ORDER BY PCS.CloseCount DESC) AS rn
    FROM 
        PostClosureStats PCS
    JOIN Posts P ON PCS.PostId = P.Id
    WHERE 
        PCS.CloseCount > 0
),
TagStats AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.Id, T.TagName
)
SELECT 
    UVS.UserId,
    UVS.DisplayName,
    UVS.TotalUpVotes,
    UVS.TotalDownVotes,
    UVS.TotalPosts,
    UVS.AvgCharsInBody,
    TCP.PostId,
    TCP.Title,
    TCP.CloseCount,
    TCP.ReopenCount,
    T.TagName,
    TS.PostCount,
    TS.TotalViews
FROM 
    UserVoteStats UVS
LEFT JOIN TopClosedPosts TCP ON UVS.TotalPosts >= 5
LEFT JOIN TagStats TS ON TS.PostCount > 0
WHERE 
    UVS.TotalUpVotes > UVS.TotalDownVotes
    AND COALESCE(TCP.CloseCount, 0) > 0
ORDER BY 
    UVS.TotalUpVotes DESC,
    TS.TotalViews DESC
FETCH FIRST 10 ROWS ONLY;
