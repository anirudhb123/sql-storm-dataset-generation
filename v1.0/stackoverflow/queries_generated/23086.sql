WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS rn,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) OVER (PARTITION BY P.Id) AS UpVoteCount,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) OVER (PARTITION BY P.Id) AS DownVoteCount,
        CASE
            WHEN closedPost.Id IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus,
        COALESCE(T.TrafficIncrease, 0) AS TrafficIncrease
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(ViewCount) AS TrafficIncrease 
         FROM 
            Posts 
         WHERE 
            ViewCount > 100 
         GROUP BY 
            PostId) T ON T.PostId = P.Id
    LEFT JOIN 
        (SELECT 
            PostId 
         FROM 
            PostHistory 
         WHERE 
            PostHistoryTypeId IN (10, 11) 
         GROUP BY 
            PostId) closedPost ON closedPost.PostId = P.Id
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
MaxTraffic AS (
    SELECT 
        MAX(TrafficIncrease) AS MaxTraffic
    FROM 
        RankedPosts
)
SELECT 
    RP.Title, 
    RP.ViewCount, 
    RP.Score, 
    RP.Reputation,
    RP.UpVoteCount,
    RP.DownVoteCount,
    RP.PostStatus,
    RP.TrafficIncrease
FROM 
    RankedPosts RP
JOIN 
    MaxTraffic MT ON RP.TrafficIncrease = MT.MaxTraffic
WHERE 
    RP.rn <= 10
ORDER BY 
    RP.Score DESC, 
    RP.ViewCount DESC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;

This query does the following:
1. Uses Common Table Expressions (CTEs) to organize and rank posts based on various criteria while retrieving related data from users and votes.
2. Utilizes window functions for row numbering and counting votes.
3. Applies conditional logic to determine if posts are closed for additional context.
4. Calculates and incorporates a traffic increase metric for the past year.
5. Filters the final selection to include only the top results based on score and view count, while applying pagination controls.
