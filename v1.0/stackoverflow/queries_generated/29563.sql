WITH TagFrequency AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS Frequency
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only include questions
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        Frequency,
        ROW_NUMBER() OVER (ORDER BY Frequency DESC) AS Rank
    FROM 
        TagFrequency
    WHERE 
        Frequency >= 10 -- Only consider tags that appear in at least 10 questions
),
QuestionWithMostVotes AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        COUNT(V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2 -- Upvotes
    WHERE 
        P.PostTypeId = 1 -- Only questions
    GROUP BY 
        P.Id
    ORDER BY 
        VoteCount DESC
    LIMIT 5
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days' -- Posts created in the last 30 days
)
SELECT 
    Q.Title AS QuestionTitle,
    T.TagName,
    T.Frequency,
    RV.QuestionId AS MostVotedQuestionId,
    RV.Title AS MostVotedQuestionTitle,
    RV.VoteCount AS MostVotedQuestionVoteCount,
    RP.PostId AS RecentPostId,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostCreationDate,
    RP.ViewCount AS RecentPostViewCount,
    RP.OwnerDisplayName AS RecentPostOwner
FROM 
    TopTags T
LEFT JOIN 
    QuestionWithMostVotes RV ON T.TagName = ANY (string_to_array((SELECT Tags FROM Posts WHERE Id = RV.QuestionId), '><')) 
LEFT JOIN 
    RecentPosts RP ON T.TagName = ANY (string_to_array((SELECT Tags FROM Posts WHERE Id = RP.PostId), '><')) 
ORDER BY 
    T.Frequency DESC, 
    RV.VoteCount DESC, 
    RP.CreationDate DESC;
