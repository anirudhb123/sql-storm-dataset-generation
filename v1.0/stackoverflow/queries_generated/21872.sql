WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
TopReputedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '5 year'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(DISTINCT p.Id) > 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerReputation,
    tru.UserId,
    tru.DisplayName AS TopUserDisplayName,
    tru.Reputation AS TopUserReputation,
    COALESCE(pc.CommentCount, 0) AS CommentsCount,
    CASE 
        WHEN rp.Score IS NULL THEN 'Score Not Available' 
        WHEN rp.Score < 0 THEN 'Negative Score'
        ELSE 'Positive Score'
    END AS ScoreStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(Id) AS CommentCount 
     FROM 
         Comments 
     GROUP BY 
         PostId) pc ON rp.PostId = pc.PostId
JOIN 
    TopReputedUsers tru ON tru.Reputation >= (SELECT AVG(Reputation) FROM Users)
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.CreationDate DESC
OFFSET 50 ROWS FETCH NEXT 10 ROWS ONLY
UNION ALL
SELECT 
    NULL AS PostId,
    'End of Results' AS Title,
    NULL AS CreationDate,
    NULL AS Score,
    NULL AS ViewCount,
    NULL AS OwnerReputation,
    NULL AS UserId,
    NULL AS TopUserDisplayName,
    NULL AS TopUserReputation,
    NULL AS CommentsCount,
    NULL AS ScoreStatus
ORDER BY 
    PostId DESC NULLS LAST;
