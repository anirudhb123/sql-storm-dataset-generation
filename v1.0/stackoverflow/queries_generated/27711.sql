WITH UserStatistics AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(P.ViewCount) AS TotalViews
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    WHERE
        U.Reputation > 1000
    GROUP BY
        U.Id
),
MostActiveUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        BadgeCount,
        UpVotes,
        DownVotes,
        TotalViews,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM
        UserStatistics
),
PostDetails AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        STUFF((SELECT ', ' + T.TagName
               FROM Tags T
               WHERE T.Id IN (SELECT UNNEST(string_to_array(P.Tags, '><'))::int))
               FOR XML PATH('')), 1, 2, '') AS Tags,
        U.DisplayName AS Author,
        P.ViewCount,
        P.Score
    FROM
        Posts P
    JOIN
        Users U ON P.OwnerUserId = U.Id
    WHERE
        P.CreationDate >= NOW() - INTERVAL '1 year' AND
        P.PostTypeId = 1 -- Only questions
),
TopPosts AS (
    SELECT
        PD.PostId,
        PD.Title,
        PD.ViewCount,
        PD.Score,
        ROW_NUMBER() OVER (ORDER BY PD.ViewCount DESC, PD.Score DESC) AS Rank
    FROM
        PostDetails PD
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    U.PostCount,
    U.BadgeCount,
    U.UpVotes,
    U.DownVotes,
    U.TotalViews,
    TP.Title AS TopPostTitle,
    TP.ViewCount AS TopPostViewCount,
    TP.Score AS TopPostScore
FROM
    MostActiveUsers U
JOIN
    TopPosts TP ON U.UserId = TP.PostId
WHERE
    U.Rank <= 10 AND
    TP.Rank <= 5
ORDER BY
    U.Reputation DESC, U.TotalViews DESC;
