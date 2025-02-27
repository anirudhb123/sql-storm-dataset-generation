WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        SUM(CASE WHEN P.IsClosed = true THEN 1 ELSE 0 END) AS ClosedPosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        TotalBadges,
        TotalUpvotes,
        TotalDownvotes,
        ClosedPosts,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStatistics
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.TotalPosts,
    T.TotalComments,
    T.TotalBadges,
    T.TotalUpvotes,
    T.TotalDownvotes,
    T.ClosedPosts
FROM 
    TopUsers T
WHERE 
    T.Rank <= 10
ORDER BY 
    T.Reputation DESC;

WITH RecentPostHistory AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        PH.CreationDate AS HistoryDate,
        PH.Comment,
        P.Body AS PostBody,
        U.DisplayName AS EditedBy
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    JOIN 
        Users U ON PH.UserId = U.Id
    WHERE 
        PH.CreationDate >= NOW() - INTERVAL '1 month'
),
DataPresentation AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        HistoryDate,
        Comment,
        PostBody,
        EditedBy,
        ROW_NUMBER() OVER (PARTITION BY PostId ORDER BY HistoryDate DESC) AS EditRank
    FROM 
        RecentPostHistory
)
SELECT 
    D.Title,
    D.PostId,
    D.HistoryDate,
    D.Comment,
    D.Body,
    D.EditedBy
FROM 
    DataPresentation D
WHERE 
    D.EditRank = 1
ORDER BY 
    D.HistoryDate DESC;
