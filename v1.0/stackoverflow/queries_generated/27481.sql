WITH TagCounts AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only questions
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        PostCount > 1  -- Exclude tags used only once
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(V.VoteTypeId = 2) - SUM(V.VoteTypeId = 3), 0) AS NetScore,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS AnswerCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 2  -- Only Answers
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        U.Id
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        NetScore,
        AnswerCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, NetScore DESC) AS UserRank
    FROM 
        UserReputation
    WHERE 
        Reputation > 1000  -- Minimum reputation threshold
)
SELECT 
    T.TagName,
    T.PostCount,
    U.DisplayName AS TopUserDisplayName,
    U.Reputation AS TopUserReputation,
    U.NetScore AS TopUserNetScore
FROM 
    TopTags T
JOIN 
    Posts P ON P.Tags LIKE '%' || T.TagName || '%'  -- Posts that contain the tag
JOIN 
    ActiveUsers U ON P.OwnerUserId = U.UserId
WHERE 
    U.UserRank <= 5  -- Get top 5 users per tag
ORDER BY 
    T.PostCount DESC, U.NetScore DESC;
