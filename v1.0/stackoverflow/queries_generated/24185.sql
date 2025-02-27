WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersGiven,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesReceived
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT 
        T.TagName,
        T.Count AS UsageCount,
        ROW_NUMBER() OVER (ORDER BY T.Count DESC) AS TagRank
    FROM 
        Tags T
    WHERE 
        T.Count > 5
),
UserTagStats AS (
    SELECT 
        U.UserId,
        T.TagName,
        COUNT(*) AS TagUsageCount
    FROM 
        UserStats U
    JOIN 
        Posts P ON U.UserId = P.OwnerUserId
    CROSS JOIN 
        LATERAL (
            SELECT 
                UNNEST(string_to_array(P.Tags, '<>')) AS Tag
        ) AS T
    WHERE 
        T.Tag IS NOT NULL
    GROUP BY 
        U.UserId, T.TagName
),
TopContributors AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.QuestionsAsked,
        U.AnswersGiven,
        SUM(UT.TagUsageCount) AS TotalTagsUsed
    FROM 
        UserStats U
    JOIN 
        UserTagStats UT ON U.UserId = UT.UserId
    GROUP BY 
        U.UserId, U.DisplayName, U.Reputation, U.QuestionsAsked, U.AnswersGiven
)
SELECT 
    T.TagName,
    COALESCE(SUM(TC.TotalTagsUsed), 0) AS ContributorCount,
    P.UsageCount,
    P.TagRank
FROM 
    PopularTags P
LEFT JOIN 
    UserTagStats UT ON P.TagName = UT.TagName
LEFT JOIN 
    TopContributors TC ON UT.UserId = TC.UserId
WHERE 
    P.TagRank <= 10
GROUP BY 
    T.TagName, P.UsageCount, P.TagRank
HAVING 
    COUNT(DISTINCT TC.UserId) > 0
ORDER BY 
    P.TagRank, ContributorCount DESC;

This query consists of several components:

1. **CTE UserStats**: It calculates statistics for each user with a reputation greater than 1000, counting their questions, answers, and upvotes received.
  
2. **CTE PopularTags**: It selects tags that have been used more than 5 times and ranks them based on their usage count.

3. **CTE UserTagStats**: It computes the usage of tags for each user based on the posts they have made.

4. **CTE TopContributors**: It summarizes the total tag usage counts for each user.

5. **Final SELECT**: Combines results to count contributions for the top 10 most popular tags, ensuring that display contains users that have made contributions to those tags. 

The query leverages various SQL constructs, including window functions, lateral joins, NULL handling, and complex aggregations, to derive insights about user engagement with the most popular tags. It illustrates robust SQL capabilities while addressing obscure scenarios by handling potential NULLs and ensuring filtering occurs logically for non-empty sets.
