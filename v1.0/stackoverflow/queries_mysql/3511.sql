
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(CM.Id) AS CommentCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        (SELECT AVG(Reputation) FROM Users) AS AvgReputation
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments CM ON U.Id = CM.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    GROUP BY 
        U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE((SELECT COUNT(*) FROM Votes WHERE PostId = P.Id AND VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes WHERE PostId = P.Id AND VoteTypeId = 3), 0) AS DownVotes,
        P.ViewCount,
        P.AnswerCount,
        @row_number := IF(@prev_posttype = P.PostTypeId, @row_number + 1, 1) AS PostRank,
        @prev_posttype := P.PostTypeId,
        P.OwnerUserId
    FROM 
        Posts P, (SELECT @row_number := 0, @prev_posttype := NULL) AS r 
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
),
TopPosts AS (
    SELECT 
        PD.* 
    FROM 
        PostDetails PD
    WHERE 
        PD.PostRank <= 5
)
SELECT 
    UA.DisplayName,
    UA.QuestionCount,
    UA.AnswerCount,
    UA.CommentCount,
    UA.TotalBounty,
    TP.Title,
    TP.CreationDate,
    TP.Score,
    TP.UpVotes,
    TP.DownVotes,
    TP.ViewCount
FROM 
    UserActivity UA
LEFT JOIN 
    TopPosts TP ON UA.UserId = TP.OwnerUserId
WHERE 
    UA.AvgReputation > (SELECT AVG(Reputation) FROM Users) 
ORDER BY 
    UA.TotalBounty DESC, UA.CommentCount DESC;
