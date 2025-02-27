WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.ViewCount,
        P.PostTypeId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank,
        CASE 
            WHEN P.CreationDate < NOW() - INTERVAL '1 year' THEN 'Legacy'
            WHEN P.ViewCount > 1000 THEN 'Popular'
            ELSE 'Normal'
        END AS PostCategory
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.Score, P.CreationDate, P.ViewCount, P.PostTypeId
),
UserExperience AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id) AS BadgeCount
    FROM 
        Users U
),
InterestingPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.ViewCount,
        RP.PostCategory,
        U.ReputationRank,
        U.BadgeCount
    FROM 
        RankedPosts RP
    JOIN 
        UserExperience U ON (RP.PostId = (SELECT P.Id 
                                            FROM Posts P 
                                            WHERE P.OwnerUserId = U.UserId 
                                            ORDER BY P.Score DESC 
                                            LIMIT 1))
    WHERE 
        RP.Rank <= 10 AND 
        U.Reputation > 100 AND
        (RP.PostCategory = 'Popular' OR RP.PostCategory = 'Legacy')
)

SELECT 
    IP.PostId,
    IP.Title,
    IP.Score,
    IP.ViewCount,
    IP.PostCategory,
    IP.ReputationRank,
    COALESCE(IP.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN IP.Score > 0 THEN 'Highly Rated'
        WHEN IP.Score = 0 THEN 'Moderately Rated'
        ELSE 'Poorly Rated'
    END AS RatingCategory
FROM 
    InterestingPosts IP
LEFT JOIN 
    Comments C ON IP.PostId = C.PostId
WHERE 
    (C.UserId IS NULL OR C.CreationDate > NOW() - INTERVAL '30 days')
ORDER BY 
    IP.Score DESC, 
    IP.ViewCount DESC
LIMIT 50;

This SQL query performs several advanced operations to explore a unique set of posts from a Stack Overflow-like schema. It leverages Common Table Expressions (CTEs), window functions for ranking, conditional logic for categorizing posts, outer joins, and intricate filtering criteria to produce a refined output of interesting posts relevant to active users with significant reputations and contributions.
