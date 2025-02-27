WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.ParentId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Starting from Questions

    UNION ALL

    SELECT 
        P.Id,
        P.Title,
        P.OwnerUserId,
        P.ParentId,
        Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy RPH ON P.ParentId = RPH.PostId 
    WHERE 
        P.PostTypeId = 2 -- Include Answers
),
PostVoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        STRING_AGG(PHT.Name, ', ') AS HistoryTypes,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS Badges
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostsWithStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(PVS.Upvotes, 0) AS Upvotes,
        COALESCE(PVS.Downvotes, 0) AS Downvotes,
        COALESCE(PHD.HistoryTypes, 'No History') AS HistoryTypes,
        COALESCE(PHD.HistoryCount, 0) AS HistoryCount,
        COALESCE(UB.BadgeCount, 0) AS UserBadgeCount,
        U.DisplayName AS UserDisplayName
    FROM 
        Posts P
    LEFT JOIN 
        PostVoteStats PVS ON P.Id = PVS.PostId
    LEFT JOIN 
        PostHistoryDetails PHD ON P.Id = PHD.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
)
SELECT 
    RPH.PostId AS QuestionId,
    RPH.Title AS QuestionTitle,
    PWS.UserDisplayName AS User,
    PWS.CreationDate AS QuestionDate,
    PWS.Score AS QuestionScore,
    PWS.Upvotes AS QuestionUpvotes,
    PWS.Downvotes AS QuestionDownvotes,
    PWS.HistoryTypes AS PostHistory,
    PWS.HistoryCount AS NumberOfEdits,
    RPH.Level AS AnswerLevel,
    COUNT(A.Id) AS AnswerCount
FROM 
    RecursivePostHierarchy RPH
LEFT JOIN 
    PostsWithStats PWS ON RPH.PostId = PWS.PostId
LEFT JOIN 
    Posts A ON RPH.PostId = A.ParentId
WHERE 
    PWS.UserBadgeCount > 0 -- Only include posts from users with badges
GROUP BY 
    RPH.PostId, RPH.Title, PWS.UserDisplayName, PWS.CreationDate, 
    PWS.Score, PWS.Upvotes, PWS.Downvotes, PWS.HistoryTypes, 
    PWS.HistoryCount, RPH.Level
ORDER BY 
    RPH.PostId;
