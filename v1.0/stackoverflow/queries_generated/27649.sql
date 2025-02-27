WITH TagFrequency AS (
    SELECT 
        TRIM(UNNEST(string_to_array(substring(Tags FROM 2 FOR LENGTH(Tags) - 2), '><'))) AS TagName, 
        COUNT(*) AS PostCount
    FROM Posts
    WHERE PostTypeId = 1  -- Only for Questions
    GROUP BY TagName
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Users U
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostAnalysis AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        P.CreationDate,
        P.OwnerUserId,
        TF.TagName
    FROM Posts P
    JOIN TagFrequency TF ON TF.TagName = ANY(string_to_array(substring(P.Tags FROM 2 FOR LENGTH(P.Tags) - 2), '><'))
    WHERE P.PostTypeId = 1  -- Only Questions
),
TopPosts AS (
    SELECT 
        PA.PostId,
        PA.Title,
        PA.ViewCount,
        PA.Score,
        PA.AnswerCount,
        PA.CommentCount,
        PA.CreationDate,
        PA.TagName,
        ROW_NUMBER() OVER (PARTITION BY PA.TagName ORDER BY PA.Score DESC) AS Rank
    FROM PostAnalysis PA
)
SELECT 
    U.DisplayName AS UserName,
    TP.Title,
    TP.TagName,
    TP.Score AS PostScore,
    TP.ViewCount,
    TP.AnswerCount,
    TP.CommentCount,
    U.CommentCount AS UserComments,
    U.VoteCount AS UserVotes,
    U.UpVoteCount,
    U.DownVoteCount
FROM TopPosts TP
JOIN UserEngagement U ON TP.OwnerUserId = U.UserId
WHERE TP.Rank <= 5  -- Top 5 posts per tag
ORDER BY TP.TagName, TP.Score DESC;
