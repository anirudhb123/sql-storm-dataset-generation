WITH RECURSIVE UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        DisplayName,
        (Reputation + COALESCE((SELECT SUM(BountyAmount) FROM Votes WHERE UserId = U.Id AND BountyAmount IS NOT NULL), 0)) AS TotalReputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Ranking
    FROM 
        Users U
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.TotalReputation,
        RANK() OVER (ORDER BY U.TotalReputation DESC) AS Rank
    FROM 
        UserReputation U
    WHERE 
        U.CreationDate > CURRENT_DATE - INTERVAL '1 year'
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.TotalReputation,
    COALESCE(BadgeCount.BadgeCount, 0) AS BadgeCount,
    COALESCE(PostStats.PostCount, 0) AS PostCount,
    COALESCE(VoteStats.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(VoteStats.DownVoteCount, 0) AS DownVoteCount,
    CASE 
        WHEN U.TotalReputation >= 5000 THEN 'High Reputation User'
        WHEN U.TotalReputation >= 1000 THEN 'Moderate Reputation User'
        ELSE 'New User'
    END AS UserCategory
FROM 
    TopUsers U
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount FROM Badges GROUP BY UserId) BadgeCount 
    ON U.Id = BadgeCount.UserId
LEFT JOIN 
    (SELECT OwnerUserId, COUNT(*) AS PostCount FROM Posts WHERE PostTypeId = 1 GROUP BY OwnerUserId) PostStats 
    ON U.Id = PostStats.OwnerUserId
LEFT JOIN 
    (SELECT UserId, 
             SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount, 
             SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount 
     FROM Votes 
     GROUP BY UserId) VoteStats 
    ON U.Id = VoteStats.UserId
WHERE 
    U.Rank <= 10
ORDER BY 
    U.TotalReputation DESC;

WITH PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        AVG(P.Score) AS AverageScore,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title
)
SELECT 
    PA.PostId,
    PA.Title,
    PA.CloseCount,
    PA.AverageScore,
    PA.CommentCount,
    CASE 
        WHEN PA.CloseCount > 5 THEN 'Frequently Closed'
        WHEN PA.AverageScore > 100 THEN 'Highly Scored'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    PostAnalytics PA
WHERE 
    PA.AverageScore IS NOT NULL
ORDER BY 
    PA.AverageScore DESC;

SELECT 
    DISTINCT T.TagName, 
    COUNT(P.Id) AS PostCount, 
    AVG(V.Count) AS AverageScorePerPost 
FROM 
    Tags T 
INNER JOIN 
    Posts P ON P.Tags LIKE '%' || T.TagName || '%'
LEFT JOIN 
    (
        SELECT 
            PostId, 
            COUNT(*) AS Count 
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 2 
        GROUP BY 
            PostId
    ) V ON V.PostId = P.Id
GROUP BY 
    T.TagName 
HAVING 
    COUNT(P.Id) > 10 
ORDER BY 
    AverageScorePerPost DESC;
