WITH UserPostStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        PostCount,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM
        UserPostStats
),
RecentVotes AS (
    SELECT
        V.PostId,
        COUNT(*) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Votes V
    WHERE
        V.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY
        V.PostId
),
PostDetails AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(R.VoteCount, 0) AS VoteCount,
        COALESCE(R.UpVotes, 0) AS UpVotes,
        COALESCE(R.DownVotes, 0) AS DownVotes,
        T.TagName,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS TagRank
    FROM
        Posts P
    LEFT JOIN
        RecentVotes R ON P.Id = R.PostId
    LEFT JOIN
        Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE
        P.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT
    U.UserId,
    U.DisplayName,
    U.PostCount,
    U.TotalScore,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.VoteCount,
    P.UpVotes,
    P.DownVotes,
    STRING_AGG(DISTINCT P.TagName, ', ') AS Tags
FROM
    TopUsers U
JOIN
    PostDetails P ON U.UserId = P.OwnerUserId
WHERE
    U.ScoreRank <= 10 AND P.TagRank = 1
GROUP BY
    U.UserId, U.DisplayName, U.PostCount, U.TotalScore, P.PostId, P.Title, P.CreationDate, P.VoteCount, P.UpVotes, P.DownVotes
ORDER BY
    U.TotalScore DESC, U.PostCount DESC;
