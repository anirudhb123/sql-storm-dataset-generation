WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE 
            WHEN V.VoteTypeId = 2 THEN 1 
            WHEN V.VoteTypeId = 3 THEN -1 
            ELSE 0 
        END) AS ReputationChange,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 1) AS QuestionCount,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 2) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        ReputationChange,
        BadgeCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY ReputationChange DESC, BadgeCount DESC) AS UserRank
    FROM 
        UserReputation
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  -- Closed and Reopened
    GROUP BY 
        PH.PostId
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(T.Tags, '><')) AS TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Posts P
    JOIN 
        Tags T ON P.Id = T.ExcerptPostId
    GROUP BY 
        TagName
    HAVING 
        COUNT(P.Id) > 5  -- More than 5 posts with tag
),
CombinedData AS (
    SELECT 
        U.DisplayName,
        U.ReputationChange,
        U.BadgeCount,
        U.QuestionCount,
        U.AnswerCount,
        COALESCE(CP.CloseCount, 0) AS TotalClosedPosts,
        PT.TagName,
        PT.PostCount
    FROM 
        TopUsers U
    LEFT JOIN 
        ClosedPosts CP ON U.UserId = CP.PostId
    LEFT JOIN 
        PopularTags PT ON U.UserId = PT.TagName
)
SELECT 
    DisplayName,
    ReputationChange,
    BadgeCount,
    QuestionCount,
    AnswerCount,
    TotalClosedPosts,
    TagName,
    PostCount
FROM 
    CombinedData
WHERE 
    (TotalClosedPosts > 0 OR TagName IS NOT NULL)
ORDER BY 
    ReputationChange DESC, BadgeCount DESC, TotalClosedPosts DESC
LIMIT 100;
