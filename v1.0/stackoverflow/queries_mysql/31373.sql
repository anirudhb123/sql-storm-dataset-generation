
WITH RECURSIVE UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Name AS BadgeName,
        B.Class,
        B.Date,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
),
QuestionDetails AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COALESCE(CASE WHEN P.ClosedDate IS NOT NULL THEN 'Closed' ELSE 'Open' END, 'Open') AS Status,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        GROUP_CONCAT(DISTINCT T.TagName ORDER BY T.TagName SEPARATOR ', ') AS Tags
    FROM
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '>', n.n), '>', -1)) AS TagName
         FROM Posts P CROSS JOIN (SELECT a.N + b.N * 10 n FROM 
         (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a, 
         (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b 
         ORDER BY n) n
         WHERE n.n <= CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '>', '')) + 1) AS T ON TRUE
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount, P.ClosedDate
),
VoteSummary AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 WHEN V.VoteTypeId = 3 THEN -1 ELSE 0 END) AS VoteScore
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
FinalResults AS (
    SELECT 
        Q.QuestionId,
        Q.Title,
        Q.CreationDate,
        Q.Score + COALESCE(V.VoteScore, 0) AS TotalScore,
        Q.ViewCount,
        Q.AnswerCount,
        Q.CommentCount,
        Q.Status,
        Q.Tags,
        (SELECT COUNT(*) FROM UserBadges UB WHERE UB.UserId = P.OwnerUserId AND UB.Class = 1) AS GoldBadges,
        (SELECT COUNT(*) FROM UserBadges UB WHERE UB.UserId = P.OwnerUserId AND UB.Class = 2) AS SilverBadges,
        (SELECT COUNT(*) FROM UserBadges UB WHERE UB.UserId = P.OwnerUserId AND UB.Class = 3) AS BronzeBadges
    FROM 
        QuestionDetails Q
    LEFT JOIN 
        VoteSummary V ON Q.QuestionId = V.PostId
    LEFT JOIN 
        Posts P ON Q.QuestionId = P.Id
)
SELECT 
    FR.*,
    CONCAT(FR.GoldBadges, ' Gold, ', FR.SilverBadges, ' Silver, ', FR.BronzeBadges, ' Bronze') AS BadgeSummary
FROM 
    FinalResults FR
WHERE 
    FR.AnswerCount > 0
ORDER BY 
    FR.TotalScore DESC, FR.ViewCount DESC
LIMIT 10;
