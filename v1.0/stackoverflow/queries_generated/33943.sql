WITH RecursivePostCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Questions only

    UNION ALL

    SELECT 
        P2.Id,
        CONCAT('Sub-answer to: ', P1.Title) AS Title,
        P2.OwnerUserId,
        P2.CreationDate,
        P2.Score,
        P2.ViewCount,
        Level + 1
    FROM 
        Posts P1
    INNER JOIN 
        Posts P2 ON P1.Id = P2.ParentId
    INNER JOIN 
        RecursivePostCTE CTE ON CTE.PostId = P1.Id
    WHERE 
        P2.PostTypeId = 2 -- Answers only
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
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
),
PostScores AS (
    SELECT 
        P.Id AS PostId,
        P.Score,
        COALESCE(V.UpVotes, 0) AS UpVotes,
        COALESCE(V.DownVotes, 0) AS DownVotes,
        CAST(P.Score AS FLOAT) / NULLIF((COALESCE(V.UpVotes, 0) + COALESCE(V.DownVotes, 0)), 0) AS FLOAT) AS ScoreImpact
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) V ON P.Id = V.PostId
),
FinalResults AS (
    SELECT 
        CTE.PostId,
        CTE.Title,
        U.DisplayName,
        U.BadgeCount,
        PS.Score,
        PS.UpVotes,
        PS.DownVotes,
        PS.ScoreImpact
    FROM 
        RecursivePostCTE CTE
    INNER JOIN 
        UserBadges U ON CTE.OwnerUserId = U.UserId
    INNER JOIN 
        PostScores PS ON CTE.PostId = PS.PostId
)
SELECT 
    FR.PostId,
    FR.Title,
    FR.DisplayName,
    FR.BadgeCount,
    FR.Score,
    FR.UpVotes,
    FR.DownVotes,
    FR.ScoreImpact,
    CASE 
        WHEN FR.Score > 100 THEN 'High Score'
        WHEN FR.Score BETWEEN 50 AND 100 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    FinalResults FR
ORDER BY 
    FR.Score DESC, FR.CreationDate DESC
LIMIT 100;
