WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    GROUP BY 
        U.Id, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(C.Id) AS CommentCount,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.OwnerUserId
),
UserPostRank AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        UPS.Rank,
        UPS.PostId,
        UPS.Title,
        UPS.ViewCount,
        UPS.UpVotes,
        UPS.DownVotes,
        CASE 
            WHEN UPS.Score IS NULL THEN 'No Score'
            ELSE   CASE 
                        WHEN UPS.Score > 10 THEN 'High Performer'
                        WHEN UPS.Score BETWEEN 1 AND 10 THEN 'Moderate Performer'
                        ELSE 'Low Performer'
                    END
        END AS PerformanceCategory
    FROM 
        Users U
    INNER JOIN 
        PostStatistics UPS ON UPS.PostId IN (
            SELECT P.Id 
            FROM Posts P 
            WHERE P.OwnerUserId = U.Id
        )
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    U.BadgeNames,
    UPR.Title,
    UPR.ViewCount,
    UPR.UpVotes,
    UPR.DownVotes,
    UPR.Rank,
    UPR.PerformanceCategory
FROM 
    UserBadges U
JOIN 
    UserPostRank UPR ON U.UserId = UPR.UserId
WHERE 
    U.Reputation > (SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL)
    AND UPR.Rank <= 5
ORDER BY 
    U.Reputation DESC, 
    UPR.Rank
OFFSET 10 ROWS
FETCH NEXT 5 ROWS ONLY;
