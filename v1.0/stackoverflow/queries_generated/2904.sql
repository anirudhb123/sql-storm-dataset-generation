WITH UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        (U.UpVotes - U.DownVotes) AS NetVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.UpVotes, U.DownVotes
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        NetVotes,
        PostCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserScore
    WHERE 
        Reputation > 1000
),
PostActivity AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        P.Score,
        P.ViewCount,
        COALESCE(COUNT(C.ID), 0) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id
),
UserPostActivities AS (
    SELECT 
        U.DisplayName AS UserName,
        P.Title AS PostTitle,
        PA.CreationDate AS PostCreationDate,
        PA.LastActivityDate AS PostLastActivity,
        PA.Score AS PostScore,
        PA.ViewCount AS PostViewCount,
        PA.CommentCount,
        PA.TotalBounty,
        CASE 
            WHEN PA.Score > 100 THEN 'Highly Scored'
            WHEN PA.Score BETWEEN 50 AND 100 THEN 'Moderately Scored'
            ELSE 'Low Scored'
        END AS ScoreCategory
    FROM 
        TopUsers U
    JOIN 
        Posts P ON U.UserId = P.OwnerUserId
    JOIN 
        PostActivity PA ON P.Id = PA.Id
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    PA.PostTitle,
    PA.PostCreationDate,
    PA.PostLastActivity,
    PA.PostScore,
    PA.ViewCount,
    PA.CommentCount,
    PA.TotalBounty,
    PA.ScoreCategory
FROM 
    UserPostActivities PA
JOIN 
    TopUsers U ON PA.UserName = U.DisplayName
WHERE 
    PA.CommentCount > 5
ORDER BY 
    U.Reputation DESC, PA.PostScore DESC;
