WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(*) OVER (PARTITION BY pt.Name) AS TotalPosts,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsAggregated
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        STRING_TO_ARRAY(p.Tags, ',') AS TagArray ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TagArray
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
BadgedPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    WHERE 
        b.Date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        p.Id
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.ScoreRank,
        ur.DisplayName,
        ur.Reputation AS UserReputation,
        CASE 
            WHEN ur.Reputation IS NULL THEN 'Unknown'
            ELSE ur.Reputation::text
        END AS ReputationDisplay,
        bp.BadgeCount,
        rp.TagsAggregated
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserReputation ur ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId LIMIT 1)
    LEFT JOIN 
        BadgedPosts bp ON bp.PostId = rp.PostId
)
SELECT 
    *,
    CASE 
        WHEN ScoreRank = 1 THEN 'Top scorer in category'
        ELSE 'Rank ' || ScoreRank || ' in category with total posts: ' || TotalPosts
    END AS RankDescription
FROM 
    FinalResults
WHERE 
    (BadgeCount > 0 OR UserReputation > 100)
ORDER BY 
    Score DESC, ViewCount DESC;

-- Special note about NULL handling in queries: 
-- We are converting NULL reputations to 'Unknown' and using CASE statements as part of our transformations 
-- to ensure meaningful output even if some relationships don't produce valid rows.
