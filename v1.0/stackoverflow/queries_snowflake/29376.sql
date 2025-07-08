
WITH TagUsage AS (
    SELECT 
        TRIM(SPLIT_PART(SPLIT_PART(Tags, '<', seq.i), '>', 1)) AS Tag,
        COUNT(*) AS UsageCount,
        AVG(VoteCount) AS AvgVotes,
        COUNT(DISTINCT OwnerUserId) AS UniqueUsers
    FROM 
        Posts
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) AS VoteSummary ON Posts.Id = VoteSummary.PostId
    LEFT JOIN (
        SELECT seq.i
        FROM TABLE(GENERATOR(ROWCOUNT => 100)) seq
    ) AS seq ON seq.i <= (LENGTH(Tags) - LENGTH(REPLACE(Tags, '<', '')) + LENGTH(Tags) - LENGTH(REPLACE(Tags, '>', ''))) / 2
    WHERE 
        PostTypeId = 1 AND 
        Tags IS NOT NULL
    GROUP BY 
        TRIM(SPLIT_PART(SPLIT_PART(Tags, '<', seq.i), '>', 1)), 
        seq.i
),
TagStats AS (
    SELECT 
        Tag,
        SUM(UsageCount) AS TotalUsage,
        SUM(AvgVotes) AS TotalAvgVotes,
        SUM(UniqueUsers) AS TotalUniqueUsers
    FROM 
        TagUsage
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TotalUsage,
        TotalAvgVotes,
        TotalUniqueUsers,
        RANK() OVER (ORDER BY TotalUsage DESC) AS TagRank
    FROM 
        TagStats
)
SELECT 
    T.Tag,
    T.TotalUsage,
    T.TotalAvgVotes,
    U.DisplayName,
    U.Reputation,
    B.Name AS BadgeName,
    B.Date AS BadgeDate
FROM 
    TopTags T
JOIN 
    Users U ON U.Id IN (SELECT OwnerUserId FROM Posts WHERE Tags ILIKE '%' || T.Tag || '%')
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    T.TagRank <= 10
ORDER BY 
    T.TotalUsage DESC, U.Reputation DESC;
