WITH UserVoteStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        AVG(U.Reputation) AS AvgReputation,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS VoteRank
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    GROUP BY
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        PostCount,
        AvgReputation
    FROM
        UserVoteStats
    WHERE
        VoteRank <= 10
),
RecentPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        CASE
            WHEN P.AcceptedAnswerId IS NOT NULL THEN
                (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.AcceptedAnswerId AND V.VoteTypeId = 3)
            ELSE 0
        END AS UpVoteCountAccepted
    FROM
        Posts P
    INNER JOIN
        Users U ON P.OwnerUserId = U.Id
    WHERE
        P.CreationDate >= NOW() - INTERVAL '30 days'
),
PostDetails AS (
    SELECT
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.OwnerDisplayName,
        RP.UpVoteCountAccepted,
        COALESCE(PT.Name, 'Unknown') AS PostType,
        COALESCE(PT.Count, 0) AS TagsCount
    FROM
        RecentPosts RP
    LEFT JOIN
        (SELECT
            T.Id,
            T.TagName,
            COUNT(*) AS Count
        FROM
            Tags T
        INNER JOIN
            Posts P ON P.Tags LIKE '%' || T.TagName || '%'
        GROUP BY T.Id, T.TagName) PT ON PT.Id = (SELECT
            MIN(Tag.Id)
        FROM
            Tags Tag
        WHERE
            RP.Tags LIKE '%' || Tag.TagName || '%')
),
FinalResult AS (
    SELECT
        TU.DisplayName AS TopUser,
        PD.Title AS RecentPostTitle,
        PD.CreationDate AS PostCreationDate,
        PD.UpVoteCountAccepted,
        PD.PostType,
        PD.TagsCount
    FROM
        TopUsers TU
    LEFT JOIN
        PostDetails PD ON TU.UserId = PD.OwnerDisplayName
    WHERE
        PD.UpVoteCountAccepted > 0
)
SELECT
    FR.TopUser,
    FR.RecentPostTitle,
    TO_CHAR(FR.PostCreationDate, 'YYYY-MM-DD HH24:MI:SS') AS FormattedCreationDate,
    FR.UpVoteCountAccepted,
    (CASE
        WHEN FR.TagsCount IS NULL THEN 'No Tags'
        WHEN FR.TagsCount > 5 THEN 'Many Tags'
        ELSE 'Some Tags'
    END) AS TagsDescription
FROM
    FinalResult FR
ORDER BY
    FR.UpVoteCountAccepted DESC,
    FR.TopUser ASC;
