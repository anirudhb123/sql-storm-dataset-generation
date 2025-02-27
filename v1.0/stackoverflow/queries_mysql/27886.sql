
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS Rank
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.PostTypeId = 1 
    GROUP BY P.Id, P.Title, P.Body, P.CreationDate, U.DisplayName
),
FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.CreationDate,
        RP.OwnerDisplayName,
        RP.CommentCount,
        RP.UpVoteCount,
        RP.DownVoteCount
    FROM RankedPosts RP
    WHERE RP.Rank <= 5 
),
PostsWithTags AS (
    SELECT 
        FP.PostId,
        FP.Title,
        FP.Body,
        FP.CreationDate,
        FP.OwnerDisplayName,
        FP.CommentCount,
        FP.UpVoteCount,
        FP.DownVoteCount,
        GROUP_CONCAT(T.TagName ORDER BY T.TagName SEPARATOR ', ') AS Tags
    FROM FilteredPosts FP
    LEFT JOIN Posts P ON FP.PostId = P.Id
    LEFT JOIN (
        SELECT 
            P.Id AS PostId,
            SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM 
            (SELECT @row := @row + 1 AS n FROM 
                (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) numbers, 
                (SELECT @row := 0) r) numbers
            JOIN Posts P ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1
        ) T ON FP.PostId = T.PostId
    GROUP BY FP.PostId, FP.Title, FP.Body, FP.CreationDate, FP.OwnerDisplayName, FP.CommentCount, FP.UpVoteCount, FP.DownVoteCount
)
SELECT 
    PostId,
    Title,
    Body,
    CreationDate,
    OwnerDisplayName,
    CommentCount,
    UpVoteCount,
    DownVoteCount,
    Tags
FROM PostsWithTags
ORDER BY CreationDate DESC
LIMIT 10;
