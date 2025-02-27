WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COALESCE(COUNT(DISTINCT P.Id), 0) AS PostCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Views,
        TotalUpvotes,
        TotalDownvotes,
        PostCount,
        QuestionCount,
        AnswerCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        DENSE_RANK() OVER (ORDER BY Views DESC) AS ViewsRank
    FROM 
        UserStats
),
FilteredUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Views,
        TotalUpvotes,
        TotalDownvotes,
        PostCount,
        QuestionCount,
        AnswerCount,
        ReputationRank,
        ViewsRank
    FROM 
        RankedUsers
    WHERE 
        Reputation > 100 AND (TotalUpvotes - TotalDownvotes) > 20
),
TopTags AS (
    SELECT 
        A.TagName,
        COUNT(*) AS TagCount
    FROM 
        Tags A
    JOIN 
        Posts B ON B.Tags LIKE CONCAT('%', A.TagName, '%')
    GROUP BY 
        A.TagName
    HAVING 
        COUNT(*) > 5
),
UserEngagement AS (
    SELECT 
        F.UserId,
        F.DisplayName,
        T.TagName,
        T.TagCount,
        CASE 
            WHEN T.TagCount > 10 THEN 'Active Contributor'
            WHEN T.TagCount BETWEEN 6 AND 10 THEN 'Moderate Contributor'
            ELSE 'New Contributor'
        END AS ContributorLevel
    FROM 
        FilteredUsers F
    JOIN 
        PostLinks PL ON F.UserId = PL.PostId
    JOIN 
        TopTags T ON PL.RelatedPostId = T.TagName
)
SELECT 
    F.UserId,
    F.DisplayName,
    F.Reputation,
    F.Views,
    F.TotalUpvotes,
    F.TotalDownvotes,
    F.PostCount,
    F.QuestionCount,
    F.AnswerCount,
    U.TagName,
    U.TagCount,
    U.ContributorLevel
FROM 
    FilteredUsers F
LEFT JOIN 
    UserEngagement U ON F.UserId = U.UserId
WHERE 
    F.ReputationRank <= 10
ORDER BY 
    F.Reputation DESC, U.TagCount DESC;
