WITH RecursivePostHierarchy AS (
    -- Recursive CTE to retrieve all answers for questions and maintain hierarchy
    SELECT P.Id AS PostId, P.Title, P.ParentId, P.OwnerUserId, P.CreationDate, 
           1 AS Level
    FROM Posts P
    WHERE P.PostTypeId = 1 -- Questions

    UNION ALL

    SELECT P.Id, P.Title, P.ParentId, P.OwnerUserId, P.CreationDate, 
           PH.Level + 1
    FROM Posts P
    INNER JOIN RecursivePostHierarchy PH ON P.ParentId = PH.PostId
    WHERE P.PostTypeId = 2 -- Answers
),

UserBadgeCounts AS (
    -- CTE to count badges per user
    SELECT U.Id AS UserId, U.DisplayName,
           COUNT(B.Id) AS BadgeCount,
           SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),

PostVoteStats AS (
    -- CTE to aggregate vote counts for posts
    SELECT P.Id, 
           COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
           COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
           COUNT(V.Id) AS TotalVotes
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.PostTypeId IN (1, 2) -- Questions and Answers
    GROUP BY P.Id
)

SELECT PH.PostId, PH.Title, 
       U.DisplayName AS Owner, 
       COALESCE(PVS.UpVotes, 0) AS UpVotes,
       COALESCE(PVS.DownVotes, 0) AS DownVotes,
       UBC.BadgeCount, UBC.GoldBadges,
       ROW_NUMBER() OVER (PARTITION BY PH.OwnerUserId ORDER BY PH.CreationDate DESC) AS PostRank,
       PH.Level AS AnswerLevel
FROM RecursivePostHierarchy PH
JOIN Users U ON PH.OwnerUserId = U.Id
LEFT JOIN UserBadgeCounts UBC ON U.Id = UBC.UserId
LEFT JOIN PostVoteStats PVS ON PH.PostId = PVS.Id
WHERE PH.Level <= 3 -- Limit to top level answers
AND (UBC.BadgeCount IS NULL OR UBC.BadgeCount > 0) -- Ensure user has badges or is NULL
ORDER BY PH.Title, PostRank;
