
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(IFNULL(P.ViewCount, 0)) AS TotalViews,
        MAX(P.Score) AS HighestScore,
        MIN(P.CreationDate) AS EarliestPost
    FROM 
        Users AS U
    LEFT JOIN 
        Posts AS P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        COUNT(P.Id) > 0
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalViews,
        HighestScore,
        EarliestPost,
        @row_num := @row_num + 1 AS Rank
    FROM 
        UserPostStats, (SELECT @row_num := 0) AS init
    ORDER BY 
        TotalViews DESC
),

HighScorePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        U.DisplayName AS OwnerName,
        CASE 
            WHEN P.Score > 0 THEN 'Positive'
            WHEN P.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ScoreType,
        GROUP_CONCAT(DISTINCT TRIM(T.TagName)) AS PostTags
    FROM 
        Posts AS P
    JOIN 
        Users AS U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        (SELECT TRIM(tag_name) AS tag_name FROM (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, ',', numbers.n), ',', -1)) AS tag_name FROM 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
            WHERE CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, ',', '')) >= numbers.n - 1) AS t) AS tag_name ON TRUE
    LEFT JOIN 
        Tags AS T ON T.TagName = tag_name.tag_name
    WHERE 
        P.Score IS NOT NULL
    GROUP BY 
        P.Id, U.DisplayName
    ORDER BY 
        P.Score DESC
),

PostHistoryWithComments AS (
    SELECT 
        PH.Id AS HistoryId,
        PH.PostId,
        PH.CreationDate,
        PH.UserId,
        PH.Comment,
        PH.Text AS HistoryText,
        C.Text AS CommentText,
        @comment_rank := IF(@prev_post_id = PH.PostId, @comment_rank + 1, 1) AS CommentRank,
        @prev_post_id := PH.PostId
    FROM 
        PostHistory AS PH
    LEFT JOIN 
        Comments AS C ON PH.PostId = C.PostId AND PH.CreationDate < C.CreationDate
    CROSS JOIN 
        (SELECT @prev_post_id := NULL, @comment_rank := 0) AS init
    WHERE 
        PH.PostHistoryTypeId NOT IN (12, 13) 
)

SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    COALESCE(TU.TotalPosts, 0) AS TotalPosts,
    COALESCE(TU.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(TU.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(TU.TotalViews, 0) AS TotalViews,
    (SELECT COUNT(*) FROM HighScorePosts WHERE OwnerName = U.DisplayName AND Score > 0) AS PositivePostCount,
    (SELECT COUNT(*) FROM HighScorePosts WHERE OwnerName = U.DisplayName AND Score < 0) AS NegativePostCount,
    GROUP_CONCAT(DISTINCT PH.Comment) AS RecentComments
FROM 
    Users AS U
LEFT JOIN 
    TopUsers AS TU ON U.Id = TU.UserId
LEFT JOIN 
    PostHistoryWithComments AS PH ON U.Id = PH.UserId
WHERE 
    U.Reputation > 1000
GROUP BY 
    U.DisplayName, U.Reputation, TU.TotalPosts, TU.TotalQuestions, TU.TotalAnswers, TU.TotalViews
ORDER BY 
    U.Reputation DESC,
    COALESCE(TU.TotalPosts, 0) DESC;
