WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS Answers,
        SUM(V.BountyAmount) AS TotalBounty,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    WHERE U.Reputation > 0
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.Views, U.UpVotes, U.DownVotes
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        Views, 
        UpVotes, 
        DownVotes, 
        TotalPosts, 
        Questions, 
        Answers, 
        TotalBounty,
        UserRank
    FROM UserStats
    WHERE UserRank <= 10
),
PostAnalysis AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.CommentCount,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM Posts P
    LEFT JOIN STRING_TO_ARRAY(P.Tags, ',') AS TagIds ON TRUE
    LEFT JOIN Tags T ON T.Id::text = ANY(STRING_TO_ARRAY(P.Tags, '><')) 
    WHERE P.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.CommentCount
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalBounty,
    PA.Title,
    PA.CreationDate,
    PA.ViewCount,
    PA.Score,
    PA.CommentCount,
    PA.Tags
FROM TopUsers TU
JOIN PostAnalysis PA ON TU.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Title LIKE '%' || PA.Title || '%')
ORDER BY TU.TotalBounty DESC, PA.ViewCount DESC;
