
WITH TagFrequency AS (
    SELECT
        value AS Tag,
        COUNT(*) AS Frequency
    FROM
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE
        PostTypeId = 1  
    GROUP BY
        value
),
TopUsers AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(ISNULL(P.Score, 0)) AS TotalScore,
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
        ISNULL(COUNT(C.Id), 0) AS CommentCount,
        ISNULL(COUNT(V.Id), 0) AS VoteCount
    FROM
        Posts P
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    WHERE
        P.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56')
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
        TagFrequency TF ON TF.Tag IN (SELECT value FROM STRING_SPLIT(SUBSTRING(R.Title, 2, LEN(R.Title) - 2), '><'))
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
