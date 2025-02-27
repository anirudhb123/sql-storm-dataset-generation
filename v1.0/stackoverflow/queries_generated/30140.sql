WITH RecursiveUserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN VT.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VT.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN VoteTypes VT ON V.VoteTypeId = VT.Id
    GROUP BY U.Id, U.DisplayName
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        COALESCE(P.AnswerCount, 0) AS TotalAnswers,
        COALESCE(CV.VoteCount, 0) AS TotalVotes,
        COALESCE(CV.UpVotes, 0) AS TotalUpVotes,
        COALESCE(CV.DownVotes, 0) AS TotalDownVotes
    FROM Users U
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            COUNT(*) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2
        GROUP BY OwnerUserId
    ) P ON U.Id = P.OwnerUserId
    LEFT JOIN RecursiveUserVotes CV ON U.Id = CV.UserId
),
PopularTags AS (
    SELECT 
        TagId,
        COUNT(*) AS TagUsage
    FROM (
        SELECT 
            UNNEST(string_to_array(Tags, ',')) AS TagId
        FROM Posts
        WHERE PostTypeId = 1
    ) AS TagList
    GROUP BY TagId
    ORDER BY TagUsage DESC
),
TopTags AS (
    SELECT 
        TagId
    FROM PopularTags
    WHERE TagUsage > 100 -- Arbitrary filter for popularity
    LIMIT 10
),
FinalResults AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.TotalAnswers,
        U.TotalVotes,
        U.TotalUpVotes,
        U.TotalDownVotes,
        T.TagId
    FROM UserPostStats U
    INNER JOIN TopTags T ON U.UserId IN (
        SELECT DISTINCT P.OwnerUserId
        FROM Posts P
        WHERE P.Tags LIKE '%' || T.TagId || '%'
    )
)
SELECT 
    FR.DisplayName,
    FR.Reputation,
    FR.TotalAnswers,
    FR.TotalVotes,
    FR.TotalUpVotes,
    FR.TotalDownVotes,
    T.TagName
FROM FinalResults FR
LEFT JOIN Tags T ON FR.TagId = T.Id
ORDER BY FR.Reputation DESC, FR.TotalAnswers DESC;
