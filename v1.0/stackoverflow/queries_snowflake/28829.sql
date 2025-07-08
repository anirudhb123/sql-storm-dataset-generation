
WITH TagFrequency AS (
    SELECT
        TRIM(SPLIT_PART(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><', seq)) AS Tag,
        COUNT(*) AS Frequency
    FROM
        Posts,
        TABLE(GENERATOR(ROWCOUNT => 1000)) seq  -- Adjust the rowcount as necessary to cover possible splits
    WHERE
        PostTypeId = 1  
        AND seq <= (LENGTH(Tags) - LENGTH(REPLACE(Tags, '><', '')) + 1)  -- Count the occurrences
    GROUP BY
        Tag
),
TopUsers AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
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
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'  
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
        TagFrequency TF ON TF.Tag IN (
            SELECT
                TRIM(SPLIT_PART(SUBSTRING(R.Title, 2, LENGTH(R.Title) - 2), '><', seq))
            FROM
                TABLE(GENERATOR(ROWCOUNT => 1000)) seq
            WHERE
                seq <= (LENGTH(R.Title) - LENGTH(REPLACE(R.Title, '><', '')) + 1)  -- Count the occurrences
        )
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
