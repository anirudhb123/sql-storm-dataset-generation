
WITH TagFrequency AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS Frequency
    FROM
        Posts
    INNER JOIN (
        SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10 
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE
        PostTypeId = 1  
    GROUP BY
        Tag
),
TopUsers AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(IFNULL(P.Score, 0)) AS TotalScore,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS Rank
    FROM
        Users U
    JOIN
        Posts P ON U.Id = P.OwnerUserId
    WHERE
        U.Reputation > 1000  
    GROUP BY
        U.Id, U.DisplayName
),
RecentActivity AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.LastActivityDate,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(COUNT(V.Id), 0) AS VoteCount
    FROM
        Posts P
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    WHERE
        P.CreationDate >= NOW() - INTERVAL 30 DAY  
    GROUP BY
        P.Id, P.Title, P.LastActivityDate
),
ActivitySummary AS (
    SELECT
        R.PostId,
        R.Title,
        R.LastActivityDate,
        R.CommentCount,
        R.VoteCount,
        TF.Tag,
        TF.Frequency
    FROM
        RecentActivity R
    JOIN
        TagFrequency TF ON FIND_IN_SET(TF.Tag, REPLACE(REPLACE(R.Title, '<', '>'), '>', '<'))
)
SELECT
    TU.Rank,
    TU.DisplayName,
    TU.QuestionCount,
    TU.TotalScore,
    ASum.PostId,
    ASum.Title,
    ASum.LastActivityDate,
    ASum.CommentCount,
    ASum.VoteCount,
    ASum.Tag,
    ASum.Frequency
FROM
    TopUsers TU
JOIN
    ActivitySummary ASum ON TU.UserId = ASum.PostId
ORDER BY
    TU.QuestionCount DESC, ASum.LastActivityDate DESC;
