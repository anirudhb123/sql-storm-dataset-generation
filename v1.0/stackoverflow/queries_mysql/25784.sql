
WITH TagPostCount AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) n
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1  
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
        PostCount > 10  
),
TagDetails AS (
    SELECT 
        Tags.TagName,
        COUNT(Tags.Id) AS TagUsageCount,
        TOP.PostCount AS TagPostCount,
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
        Posts.PostTypeId = 1  
        AND Users.Reputation > 100  
    GROUP BY 
        Tags.TagName,
        TOP.PostCount,
        Users.DisplayName,
        Users.Reputation
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
    RankedTags.PopularityRank <= 5  
ORDER BY 
    RankedTags.PopularityRank;
