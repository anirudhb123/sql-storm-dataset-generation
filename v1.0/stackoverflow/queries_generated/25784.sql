WITH TagPostCount AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only Questions
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagPostCount
    WHERE 
        PostCount > 10  -- Filtering tags with more than 10 questions
),
TagDetails AS (
    SELECT 
        Tags.TagName,
        Tags.Count AS TagUsageCount,
        TOP.Tags.TagCount AS TagPostCount,
        Users.DisplayName AS TopUserName,
        Users.Reputation AS TopUserReputation
    FROM
        Tags
    JOIN 
        TopTags TOP ON Tags.TagName = TOP.TagName
    JOIN 
        Posts ON Tags.Id = Posts.Id
    JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    WHERE 
        Posts.PostTypeId = 1  -- Only Questions
        AND Users.Reputation > 100  -- Only considering users with reputation over 100
),
RankedTags AS (
    SELECT 
        TagDetails.TagName,
        TagDetails.TagUsageCount,
        TagDetails.TagPostCount,
        TagDetails.TopUserName,
        TagDetails.TopUserReputation,
        RANK() OVER (ORDER BY TagDetails.TagPostCount DESC) AS PopularityRank
    FROM 
        TagDetails
)
SELECT 
    RankedTags.TagName,
    RankedTags.TagUsageCount,
    RankedTags.TagPostCount,
    RankedTags.TopUserName,
    RankedTags.TopUserReputation,
    RankedTags.PopularityRank
FROM 
    RankedTags
WHERE 
    RankedTags.PopularityRank <= 5  -- Get top 5 tags
ORDER BY 
    RankedTags.PopularityRank;
