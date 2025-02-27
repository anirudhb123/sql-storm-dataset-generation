WITH UserBadges AS (
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
TopQuestions AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 AND 
        P.Score > 0
),
QuestionDetails AS (
    SELECT 
        TQ.Title,
        UB.DisplayName,
        UB.BadgeCount,
        COUNT(C.Id) AS CommentCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        TopQuestions TQ
    JOIN 
        Posts P ON TQ.Id = P.Id
    JOIN 
        UserBadges UB ON P.OwnerUserId = UB.UserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        TQ.Rank <= 10
    GROUP BY 
        TQ.Title, UB.DisplayName, UB.BadgeCount
)
SELECT 
    QD.Title,
    QD.DisplayName,
    QD.BadgeCount,
    QD.CommentCount,
    (QD.UpVotes - QD.DownVotes) AS NetVotes,
    CASE 
        WHEN QD.BadgeCount > 0 THEN 'Active' 
        ELSE 'Inactive' 
    END AS UserStatus
FROM 
    QuestionDetails QD
ORDER BY 
    QD.NetVotes DESC, QD.BadgeCount DESC;
