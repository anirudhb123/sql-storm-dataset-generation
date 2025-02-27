
WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        AVG(P.Score) AS AverageScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        T.TagName
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionsAsked,
        COUNT(DISTINCT C.Id) AS CommentsMade,
        COUNT(DISTINCT V.Id) AS VotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        AverageScore,
        @row_number := @row_number + 1 AS Rank
    FROM 
        TagStatistics, (SELECT @row_number := 0) AS rn
    ORDER BY 
        TotalScore DESC
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionsAsked,
        CommentsMade,
        VotesReceived,
        UpVotesReceived,
        DownVotesReceived,
        @user_row_number := @user_row_number + 1 AS Rank
    FROM 
        UserEngagement, (SELECT @user_row_number := 0) AS rn
    ORDER BY 
        VotesReceived DESC
)

SELECT 
    TT.TagName,
    TT.PostCount,
    TT.TotalViews,
    TT.TotalScore,
    TT.AverageScore,
    TU.DisplayName AS TopUser,
    TU.QuestionsAsked,
    TU.CommentsMade,
    TU.VotesReceived,
    TU.UpVotesReceived,
    TU.DownVotesReceived
FROM 
    TopTags TT
JOIN 
    TopUsers TU ON TT.Rank = TU.Rank
WHERE 
    TT.Rank <= 10 AND TU.QuestionsAsked >= 5
ORDER BY 
    TT.TotalScore DESC;
