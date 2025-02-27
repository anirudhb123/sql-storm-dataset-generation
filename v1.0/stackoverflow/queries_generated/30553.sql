WITH RecursivePostHierarchy AS (
    -- CTE to retrieve hierarchical information about posts and their accepted answers
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.AcceptedAnswerId,
        P.CreationDate,
        P.OwnerUserId,
        P.AnswerCount
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Only questions
    UNION ALL
    SELECT 
        P2.Id,
        P2.Title,
        P2.PostTypeId,
        P2.AcceptedAnswerId,
        P2.CreationDate,
        P2.OwnerUserId,
        P2.AnswerCount
    FROM 
        Posts P2
    INNER JOIN 
        RecursivePostHierarchy R ON P2.ParentId = R.PostId
),
PostVoteStats AS (
    -- CTE to calculate various vote statistics for posts
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserBadges AS (
    -- CTE to aggregate users' badge information
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    P.Id AS PostId,
    P.Title,
    P.ViewCount,
    COALESCE(PVS.UpVotes, 0) AS UpVotes,
    COALESCE(PVS.DownVotes, 0) AS DownVotes,
    COALESCE(PVS.TotalVotes, 0) AS TotalVotes,
    U.DisplayName,
    UB.BadgeCount,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
    RPH.AnswerCount AS AcceptedAnswersCount
FROM 
    Posts P
LEFT JOIN 
    PostVoteStats PVS ON P.Id = PVS.PostId
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    RecursivePostHierarchy RPH ON P.AcceptedAnswerId = RPH.PostId
WHERE 
    P.CreationDate >= DATEADD(YEAR, -5, GETDATE()) -- Posts created in the last 5 years
ORDER BY 
    UpVotes DESC,

    /* Including a complex calculation using NULL logic */
    CASE 
        WHEN AcceptedAnswersCount IS NULL THEN 1
        ELSE 0 
    END, 
    P.ViewCount DESC

OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY; -- Fetching only the top 100 posts
