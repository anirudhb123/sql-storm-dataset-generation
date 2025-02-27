WITH RecursiveBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
UserReputation AS (
    SELECT
        Id AS UserId,
        Reputation,
        CASE 
            WHEN Location IS NOT NULL THEN Location 
            ELSE 'Unknown' 
        END AS LocationInfo,
        CreationDate,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        Users
),
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS Downvotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        p.Id
),
PostRanked AS (
    SELECT 
        PostId,
        Title,
        Score,
        Upvotes,
        Downvotes,
        CommentCount,
        RANK() OVER (ORDER BY Score DESC) AS PostRank
    FROM 
        PostDetails
    WHERE 
        Score IS NOT NULL
),
UserPostCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        AVG(CASE WHEN Score IS NOT NULL THEN Score ELSE 0 END) AS AvgPostScore
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
FinalResults AS (
    SELECT
        u.DisplayName,
        u.Reputation,
        u.LocationInfo,
        u.BadgeCount,
        p.Title,
        p.Score,
        p.Upvotes,
        p.Downvotes,
        p.CommentCount,
        pr.PostRank,
        upc.PostCount,
        upc.AvgPostScore
    FROM 
        UserReputation u
    LEFT JOIN 
        RecursiveBadgeCounts b ON u.UserId = b.UserId
    LEFT JOIN 
        PostRanked pr ON u.UserId = pr.OwnerUserId
    LEFT JOIN 
        UserPostCounts upc ON u.UserId = upc.OwnerUserId
    WHERE 
        u.Rank <= 100 AND  
        (b.BadgeCount IS NULL OR b.BadgeCount > 0)
)
SELECT 
    *
FROM 
    FinalResults
ORDER BY 
    Reputation DESC, PostRank ASC;
