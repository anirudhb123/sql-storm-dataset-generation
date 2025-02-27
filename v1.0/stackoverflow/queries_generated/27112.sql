WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only consider questions
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(V.VoteTypeId = 2) AS UpVotes,  -- Count upvotes
        SUM(V.VoteTypeId = 3) AS DownVotes  -- Count downvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1  -- Questions
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 100  -- Only consider reputable users
    GROUP BY 
        U.Id
),
PopularUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        TotalAnswers,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY QuestionCount DESC) AS UserRank
    FROM 
        UserStats
    WHERE 
        QuestionCount > 5  -- Must have more than 5 questions
)
SELECT 
    TT.TagName,
    TT.PostCount,
    PU.DisplayName,
    PU.QuestionCount,
    PU.TotalAnswers,
    PU.UpVotes,
    PU.DownVotes
FROM 
    TopTags TT
JOIN 
    PopularUsers PU ON TT.TagName LIKE '%' || ANY(string_to_array(PU.DisplayName, ' ')) || '%' -- Match tags with user names
WHERE 
    TT.TagRank <= 10  -- Focus on the top 10 tags
ORDER BY 
    TT.PostCount DESC, PU.QuestionCount DESC;
