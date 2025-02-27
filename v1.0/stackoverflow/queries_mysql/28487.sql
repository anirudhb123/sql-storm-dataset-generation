
WITH TaggedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        P.CreationDate,
        U.DisplayName AS Author,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
),
TagStats AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(Tags, 2, LENGTH(Tags)-2), '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
    (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) AS numbers INNER JOIN TaggedPosts ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        @rank := @rank + 1 AS Rank
    FROM 
        TagStats, (SELECT @rank := 0) r
    ORDER BY 
        PostCount DESC
),
TopTaggedPosts AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.Author,
        TP.CreationDate,
        TP.CommentCount,
        TP.UpVotes,
        TP.DownVotes,
        TT.Tag
    FROM 
        TaggedPosts TP
    JOIN 
        TopTags TT ON FIND_IN_SET(TT.Tag, SUBSTRING(TP.Tags, 2, LENGTH(TP.Tags)-2)) > 0
    WHERE 
        TT.Rank <= 10 
)
SELECT 
    TTP.PostId,
    TTP.Title,
    TTP.Author,
    TTP.CreationDate,
    TTP.CommentCount,
    TTP.UpVotes,
    TTP.DownVotes,
    TTP.Tag,
    (SELECT SUM(P.Score) FROM Posts P WHERE P.ParentId = TTP.PostId) AS TotalScoreForAnswers
FROM 
    TopTaggedPosts TTP
ORDER BY 
    TTP.UpVotes DESC, 
    TTP.CommentCount DESC;
