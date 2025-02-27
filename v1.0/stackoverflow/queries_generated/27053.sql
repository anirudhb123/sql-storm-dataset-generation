WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1        -- Considering only Questions
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag, 
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
    WHERE 
        PostCount > 1
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(SUM(V.VoteTypeId = 6), 0) AS CloseVotes,
        COUNT(DISTINCT P.Id) AS QuestionPosts
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    GROUP BY 
        U.Id, U.DisplayName
),
MostActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        CloseVotes,
        QuestionPosts,
        ROW_NUMBER() OVER (ORDER BY QuestionPosts DESC, UpVotes DESC) AS ActivityRank
    FROM 
        UserStatistics
)
SELECT 
    T.Tag,
    T.PostCount,
    U.DisplayName AS ActiveUser,
    U.UpVotes,
    U.DownVotes,
    U.CloseVotes
FROM 
    TopTags T
LEFT JOIN 
    MostActiveUsers U ON U.ActivityRank = 1
ORDER BY 
    T.PostCount DESC, U.UpVotes DESC; 
