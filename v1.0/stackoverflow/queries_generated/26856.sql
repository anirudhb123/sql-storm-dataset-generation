WITH RankedTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(P.Id) DESC) AS Rank
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%' )
    GROUP BY 
        T.Id, T.TagName
),
TopUsers AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        SUM(V.Count) AS TotalVotes,
        RANK() OVER (ORDER BY SUM(V.Count) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS Count
        FROM 
            Votes V
        GROUP BY 
            PostId
    ) V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        RANK() OVER (ORDER BY P.Score DESC, P.ViewCount DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 AND P.Score > 0
)
SELECT 
    R.TagName,
    R.PostCount,
    U.DisplayName AS TopVoter,
    U.TotalVotes,
    P.Title AS MostPopularPost,
    P.ViewCount,
    P.Score
FROM 
    RankedTags R
JOIN 
    TopUsers U ON U.UserRank <= 5
JOIN 
    PopularPosts P ON P.PostRank <= 5
WHERE 
    R.Rank <= 10
ORDER BY 
    R.PostCount DESC, U.TotalVotes DESC, P.Score DESC;
