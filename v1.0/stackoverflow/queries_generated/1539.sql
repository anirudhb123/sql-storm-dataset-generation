WITH UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
), PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC) AS Rank,
        COALESCE(CARDINALITY(STRING_TO_ARRAY(P.Tags, ',')), 0) AS TagCount
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1
        AND P.Score > (
            SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1
        )
), ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.Comment
    FROM 
        PostHistory PH
    INNER JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PHT.Name = 'Post Closed'
        AND PH.CreationDate >= NOW() - INTERVAL '1 YEAR'
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.UpVotes,
    US.DownVotes,
    US.PostCount,
    US.TotalScore,
    PP.Title AS PopularPostTitle,
    PP.Score AS PopularPostScore,
    PP.Rank,
    CP.CreationDate AS ClosedPostDate,
    CP.Comment AS CloseComment
FROM 
    UserScore US
LEFT JOIN 
    PopularPosts PP ON PP.Rank <= 5
LEFT JOIN 
    ClosedPosts CP ON CP.PostId = (
        SELECT 
            PostId
        FROM 
            ClosedPosts
        WHERE 
            ClosedPosts.CreationDate = (
                SELECT MAX(CreationDate) 
                FROM ClosedPosts 
                WHERE PostId = CP.PostId
            )
    )
WHERE 
    US.TotalScore > 100
ORDER BY 
    US.TotalScore DESC,
    US.UpVotes DESC;
