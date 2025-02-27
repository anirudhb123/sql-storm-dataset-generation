WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.AnswerCount ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        PT.Name AS PostType,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        unnest(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')) AS T(TagName) ON TRUE
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.CreationDate, PT.Name
),
PostInteractions AS (
    SELECT 
        P.Id AS PostId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT PL.RelatedPostId) AS LinkedPostCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostLinks PL ON P.Id = PL.PostId
    GROUP BY 
        P.Id
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    U.PostCount,
    U.TotalAnswers,
    U.TotalUpVotes,
    U.TotalDownVotes,
    PD.PostId,
    PD.Title,
    PD.ViewCount,
    PD.CreationDate,
    PD.PostType,
    PD.Tags,
    PI.CommentCount,
    PI.LinkedPostCount
FROM 
    UserStats U
JOIN 
    PostDetails PD ON U.PostCount > 0  -- Only users with at least one post
JOIN 
    PostInteractions PI ON PD.PostId = PI.PostId
ORDER BY 
    U.Reputation DESC, PD.ViewCount DESC;
