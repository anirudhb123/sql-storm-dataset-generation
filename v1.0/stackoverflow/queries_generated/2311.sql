WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users AS U
    LEFT JOIN 
        Posts AS P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes AS V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
RankedUsers AS (
    SELECT 
        UA.*,
        RANK() OVER (ORDER BY UA.Reputation DESC) AS ReputationRank,
        DENSE_RANK() OVER (ORDER BY UA.AnswerCount DESC) AS AnswerRank
    FROM 
        UserActivity AS UA
),
TopUsers AS (
    SELECT 
        R.DisplayName,
        R.Reputation,
        R.ReputationRank,
        R.AnswerCount,
        R.AnswerRank
    FROM 
        RankedUsers AS R
    WHERE 
        R.ReputationRank <= 10 OR R.AnswerRank <= 10
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.SScore,
        P.ViewCount,
        C.UserDisplayName AS MostRecentCommenter,
        C.CreationDate AS CommentDate
    FROM 
        Posts AS P
    LEFT JOIN 
        Comments AS C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.AnswerCount,
    RP.Title AS RecentPostTitle,
    RP.MostRecentCommenter,
    RP.CommentDate,
    CASE 
        WHEN TU.AnswerCount > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS UserStatus
FROM 
    TopUsers AS TU
FULL OUTER JOIN 
    RecentPosts AS RP ON TU.UserId = RP.OwnerUserId
WHERE 
    (TU.Reputation > 1000 AND RP.ViewCount > 100) OR 
    (TU.AnswerCount > 5 AND RP.CreationDate IS NOT NULL)
ORDER BY 
    TU.Reputation DESC, RP.ViewCount DESC;
