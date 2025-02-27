WITH UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounties,
        COALESCE(SUM(V.CreationDate IS NOT NULL), 0) AS TotalVotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
TopActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        CommentCount,
        TotalBounties,
        TotalVotes,
        UserRank
    FROM 
        UserActivity
    WHERE 
        UserRank <= 10
),
PostVoteHistory AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        PH.CreationDate,
        PH.PostHistoryTypeId,
        PH.UserId,
        PH.Comment,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS HistoryRank
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12, 13)  -- Close, Reopen, Delete, Undelete
),
ActivePostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE 0 END), 0) AS ReopenCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostVoteHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount
)
SELECT 
    AU.DisplayName AS ActiveUser,
    AU.PostCount,
    AU.CommentCount,
    AU.TotalBounties,
    PP.Title AS PostTitle,
    PP.Score AS PostScore,
    PP.ViewCount AS PostViews,
    PP.UpVotes,
    PP.DownVotes,
    PP.CloseCount,
    PP.ReopenCount
FROM 
    TopActiveUsers AU
JOIN 
    ActivePostDetails PP ON AU.UserId = P.OwnerUserId
ORDER BY 
    AU.TotalVotes DESC, AU.PostCount DESC;
This SQL query generates a performance benchmark by combining data related to user activity, post voting history, and comments. It utilizes Common Table Expressions (CTEs) for better readability and organization, including ranking active users, detailing post histories, and calculating post statistics with various metrics, utilizing a mix of joins, aggregates, and window functions for sophisticated data analysis.
