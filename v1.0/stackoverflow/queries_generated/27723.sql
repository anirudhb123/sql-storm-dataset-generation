WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
HighReputationUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        TotalBadges,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserStatistics
    WHERE 
        Reputation > 1000
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        ARRAY_AGG(DISTINCT T.TagName) AS Tags,
        P.CreationDate,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        UNNEST(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')) AS T(TagName) ON TRUE
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.Score, P.CreationDate
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.ViewCount,
        PS.Score,
        PS.Tags,
        PS.CreationDate,
        ROW_NUMBER() OVER (ORDER BY PS.Score DESC) AS PostRank
    FROM 
        PostSummary PS
    WHERE
        PS.ViewCount > 100
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    T.Title AS TopPostTitle,
    T.ViewCount AS TopPostViewCount,
    T.Score AS TopPostScore,
    T.CreationDate AS TopPostDate,
    T.Tags AS TopPostTags
FROM 
    HighReputationUsers U
JOIN 
    TopPosts T ON U.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = T.PostId)
WHERE 
    U.UserRank <= 10
ORDER BY 
    U.Reputation DESC, T.Score DESC;
