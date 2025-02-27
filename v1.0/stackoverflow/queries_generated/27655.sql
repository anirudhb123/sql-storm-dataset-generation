WITH TagFrequency AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only consider questions
    GROUP BY 
        Tag
),

HighestTag AS (
    SELECT 
        Tag,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagFrequency
    WHERE 
        PostCount > 10  -- Filter for tags with more than 10 questions
),

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(COALESCE(v.VoteTypeId::int, 0)) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  -- Join only questions
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 5  -- At least 5 questions
),

UserTagActivity AS (
    SELECT 
        ut.UserId,
        ht.Tag,
        COUNT(ut.PostId) AS TaggedPostCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        HighestTag ht ON ht.Tag = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))
    JOIN 
        Users ut ON p.OwnerUserId = ut.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Changes involving title, body, or tags
    GROUP BY 
        ut.UserId, ht.Tag
)

SELECT 
    u.DisplayName AS User,
    ht.Tag,
    ht.PostCount AS TotalPostsOnTag,
    uqa.TaggedPostCount AS UserPostCount,
    ROUND((uqa.TaggedPostCount::numeric / NULLIF(ht.PostCount, 0)) * 100, 2) AS UserContributionPercentage
FROM 
    HighestTag ht
JOIN 
    TopUsers u ON u.QuestionCount > 0
LEFT JOIN 
    UserTagActivity uqa ON u.UserId = uqa.UserId AND ht.Tag = uqa.Tag
ORDER BY 
    u.DisplayName, ht.Tag;
