WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TagPostStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        AVG(P.ViewCount) AS AverageViewCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(P.Score) AS TotalScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        T.TagName
),
ActiveUserTags AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        STRING_AGG(DISTINCT T.TagName, ', ') AS ActiveTags
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    JOIN 
        Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        U.Id, U.DisplayName
),
Ranking AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.PostCount,
        U.UpvoteCount,
        U.DownvoteCount,
        U.BadgeCount,
        (U.UpvoteCount - U.DownvoteCount) AS NetVotes,
        T.PostCount AS TagsPosted,
        T.AverageViewCount,
        T.CommentCount AS TagCommentCount,
        T.TotalScore AS TagScore,
        A.ActiveTags
    FROM 
        UserScores U
    LEFT JOIN 
        TagPostStats T ON T.PostCount > 0
    LEFT JOIN 
        ActiveUserTags A ON U.UserId = A.UserId
)
SELECT 
    R.DisplayName,
    R.Reputation,
    R.PostCount,
    R.UpvoteCount,
    R.DownvoteCount,
    R.NetVotes,
    R.TagsPosted,
    R.AverageViewCount,
    R.TagCommentCount,
    R.TagScore,
    R.ActiveTags
FROM 
    Ranking R
ORDER BY 
    R.NetVotes DESC, R.Reputation DESC
LIMIT 10;
