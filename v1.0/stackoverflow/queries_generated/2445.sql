WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        QuestionCount,
        TotalBounties,
        UpvoteCount,
        DownvoteCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.Reputation,
    T.PostCount,
    T.AnswerCount,
    T.QuestionCount,
    T.TotalBounties,
    T.UpvoteCount,
    T.DownvoteCount,
    CASE 
        WHEN T.TotalBounties = 0 THEN 'No Bounties' 
        ELSE 'Bounties Awarded' 
    END AS BountyStatus,
    COALESCE((
        SELECT STRING_AGG(PT.Name, ', ')
        FROM PostHistory PH
        JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
        WHERE PH.UserId = T.UserId AND PHT.Name LIKE 'Edit%'
    ), 'No Edits') AS RecentEdits
FROM 
    TopUsers T
WHERE 
    T.Rank <= 10 
ORDER BY 
    T.Rank;
