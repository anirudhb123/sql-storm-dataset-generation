WITH UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalPosts, 
        TotalComments, 
        TotalBadges, 
        TotalUpVotes, 
        TotalDownVotes, 
        LastPostDate,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalUpVotes DESC) AS ActivityRank
    FROM 
        UserActivity
)
SELECT 
    U.UserId, 
    U.DisplayName, 
    U.Reputation, 
    U.TotalPosts,
    U.TotalComments,
    U.TotalBadges,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.LastPostDate,
    TH.Name AS TopPostHistoryType
FROM 
    TopActiveUsers U
LEFT JOIN 
    PostHistory PH ON U.UserId = PH.UserId
LEFT JOIN 
    PostHistoryTypes TH ON PH.PostHistoryTypeId = TH.Id
WHERE 
    U.ActivityRank <= 10
ORDER BY 
    U.ActivityRank;
