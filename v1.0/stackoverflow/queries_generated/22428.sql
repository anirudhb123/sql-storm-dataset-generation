WITH RecursiveTagCounts AS (
    SELECT
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount
    FROM
        Tags
    LEFT JOIN
        Posts ON Posts.Tags LIKE '%' || Tags.TagName || '%'
    GROUP BY
        Tags.TagName
), 

TopTags AS (
    SELECT
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM
        RecursiveTagCounts
    WHERE
        PostCount > 0
), 

UserEngagement AS (
    SELECT
        Users.Id AS UserId,
        COUNT(Posts.Id) AS PostCount,
        SUM(COALESCE(Votes.VoteTypeId = 2, 0)) AS UpVotesGiven,
        SUM(COALESCE(Votes.VoteTypeId = 3, 0)) AS DownVotesGiven,
        AVG(Users.Reputation) AS AvgReputation
    FROM
        Users
    LEFT JOIN
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN
        Votes ON Votes.UserId = Users.Id AND Votes.PostId = Posts.Id
    GROUP BY
        Users.Id
),

PostHistoryAggregates AS (
    SELECT
        PostId,
        STRING_AGG(CONCAT(PostHistoryTypeId, ': ', Comment), '; ') AS HistoryComments,
        MAX(CASE WHEN CreationDate < NOW() - INTERVAL '1 year' THEN 1 ELSE 0 END) AS IsLegacy
    FROM
        PostHistory
    GROUP BY
        PostId
)

SELECT 
    u.DisplayName AS UserDisplayName,
    t.TagName,
    t.PostCount AS TotalPostsWithTag,
    u.PostCount AS UserPostCount,
    (u.UpVotesGiven - u.DownVotesGiven) AS EngagementScore,
    p.HistoryComments,
    p.IsLegacy,
    CASE 
        WHEN u.AvgReputation IS NOT NULL THEN 
            CASE 
                WHEN u.AvgReputation > 1000 THEN 'High Reputation'
                WHEN u.AvgReputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
                ELSE 'Low Reputation'
            END
        ELSE 'No Reputation Data'
    END AS ReputationLevel
FROM 
    TopTags t
JOIN 
    UserEngagement u ON u.PostCount > 0
LEFT JOIN 
    PostHistoryAggregates p ON p.PostId IN (SELECT PostId FROM Posts WHERE Tags LIKE '%' || t.TagName || '%')
WHERE 
    t.TagRank <= 10
ORDER BY 
    t.PostCount DESC, 
    EngagementScore DESC;
