WITH TagStatistics AS (
    SELECT
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount,
        SUM(COALESCE(Votes.UserId IS NOT NULL, 0)::int) AS TotalVotes,
        AVG(COALESCE(Posts.Score, 0)) AS AverageScore,
        STRING_AGG(DISTINCT Users.DisplayName, ', ') AS UserNames
    FROM Tags
    LEFT JOIN Posts ON Tags.Id = ANY(STRING_TO_ARRAY(SUBSTRING(Posts.Tags, 2, LENGTH(Posts.Tags)-2), '><')::int[])
    LEFT JOIN Votes ON Posts.Id = Votes.PostId
    LEFT JOIN Users ON Votes.UserId = Users.Id
    GROUP BY Tags.TagName
),

TopTags AS (
    SELECT
        TagName,
        PostCount,
        TotalVotes,
        AverageScore,
        UserNames,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM TagStatistics
),

PopularTags AS (
    SELECT
        TagName,
        PostCount,
        TotalVotes,
        AverageScore,
        UserNames
    FROM TopTags
    WHERE TagRank <= 10
),

PostDetails AS (
    SELECT
        Posts.Id AS PostId,
        Posts.Title,
        Posts.Body,
        Posts.CreationDate,
        Posts.Score,
        ARRAY_AGG(DISTINCT Tags.TagName) AS RelatedTags
    FROM Posts
    LEFT JOIN STRING_TO_ARRAY(SUBSTRING(Posts.Tags, 2, LENGTH(Posts.Tags)-2), '><') AS TagArray ON TRUE
    LEFT JOIN Tags ON TagArray::int[] = ARRAY[Tags.Id]
    GROUP BY Posts.Id
)

SELECT
    p.PostId,
    p.Title,
    p.Body,
    p.CreationDate,
    p.Score,
    tt.TagName,
    tt.PostCount,
    tt.TotalVotes,
    tt.AverageScore,
    tt.UserNames
FROM PostDetails p
INNER JOIN PopularTags tt ON tt.TagName = ANY(p.RelatedTags)
ORDER BY p.CreationDate DESC, tt.PostCount DESC;
