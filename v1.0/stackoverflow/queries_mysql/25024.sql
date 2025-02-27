
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS AuthorDisplayName,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Posts A ON A.ParentId = P.Id AND A.PostTypeId = 2
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.Body, P.Tags, U.DisplayName
),

PostStats AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Tags,
        RP.AuthorDisplayName,
        RP.CommentCount,
        RP.AnswerCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = RP.PostId AND V.VoteTypeId = 2) AS UpVoteCount, 
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = RP.PostId AND V.VoteTypeId = 3) AS DownVoteCount 
    FROM 
        RankedPosts RP
    WHERE 
        RP.PostRank = 1
),

TagCount AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1)) AS TagName, 
        COUNT(*) AS TagFrequency
    FROM 
        Posts 
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
        UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagFrequency DESC
    LIMIT 10
),

FinalResults AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.AuthorDisplayName,
        PS.CommentCount,
        PS.AnswerCount,
        PS.UpVoteCount,
        PS.DownVoteCount,
        TC.TagName,
        TC.TagFrequency
    FROM 
        PostStats PS
    CROSS JOIN 
        TagCount TC
)

SELECT 
    PostId,
    Title,
    AuthorDisplayName,
    CommentCount,
    AnswerCount,
    UpVoteCount,
    DownVoteCount,
    TagName,
    TagFrequency
FROM 
    FinalResults
ORDER BY 
    UpVoteCount DESC, 
    CommentCount DESC;
