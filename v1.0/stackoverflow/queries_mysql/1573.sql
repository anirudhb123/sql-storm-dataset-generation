
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN P.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS Status,
        PH.CreationDate AS LastEditDate,
        @row_num := CASE WHEN @post_id = P.Id THEN @row_num + 1 ELSE 1 END AS EditRank,
        @post_id := P.Id
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    CROSS JOIN (SELECT @row_num := 0, @post_id := NULL) AS init
),
TopUsers AS (
    SELECT 
        UR.DisplayName,
        UR.Reputation,
        RANK() OVER (ORDER BY UR.Reputation DESC) AS ReputationRank
    FROM 
        UserReputation UR
    WHERE 
        UR.PostCount > 5
),
RecentPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.OwnerDisplayName,
        PD.Status,
        PD.LastEditDate,
        ROW_NUMBER() OVER (ORDER BY PD.LastEditDate DESC) AS RecentRank
    FROM 
        PostDetails PD
    WHERE 
        PD.EditRank = 1
)

SELECT 
    TU.DisplayName AS TopUser,
    TU.Reputation,
    RP.Title AS RecentPostTitle,
    RP.Status,
    RP.LastEditDate
FROM 
    TopUsers TU
JOIN 
    RecentPosts RP ON RP.LastEditDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY)
ORDER BY 
    TU.Reputation DESC, RP.LastEditDate DESC
LIMIT 10;
