WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Ranking
    FROM 
        Posts p
    WHERE 
        p.CreationDate > '2020-01-01' 
        AND p.Score IS NOT NULL
        AND p.PostTypeId = 1  -- Only Questions
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High'
            WHEN u.Reputation <= 1000 AND u.Reputation > 100 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
PopularTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(p.Tags, ','))) AS TagName, 
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        TRIM(UNNEST(string_to_array(p.Tags, ',')))
    HAVING 
        COUNT(*) > 10
)
SELECT 
    up.DisplayName AS UserDisplayName,
    up.ReputationLevel,
    rp.Title,
    rp.CreationDate AS QuestionDate,
    rp.Score AS QuestionScore,
    phc.HistoryCount,
    pt.TagName,
    pt.TagCount
FROM 
    RankedPosts rp
JOIN 
    UserReputation up ON rp.OwnerUserId = up.UserId
LEFT JOIN 
    PostHistoryCounts phc ON rp.PostId = phc.PostId
LEFT JOIN 
    PopularTags pt ON pt.TagName IN (SELECT tag FROM string_to_array(rp.Title, ' '))
WHERE 
    up.ReputationLevel <> 'Low'
    AND rp.Ranking <= 3
    AND (phc.LastEditDate IS NULL OR phc.LastEditDate > rp.CreationDate)
ORDER BY 
    up.Reputation DESC, 
    rp.Score DESC;

