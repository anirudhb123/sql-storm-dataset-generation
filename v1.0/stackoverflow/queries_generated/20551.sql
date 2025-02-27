WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        COALESCE(b.Name, 'No badge') AS UserBadgeName,
        COALESCE(u.Reputation, 0) AS UserReputation,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer Exists'
            ELSE 'No Accepted Answer'
        END AS AnswerStatus,
        CASE 
            WHEN p.CreationDate < CURRENT_DATE - INTERVAL '6 months' THEN 'Old Post'
            ELSE 'Recent Post'
        END AS PostAge
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts p ON rp.PostId = p.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id AND b.Class = 1 -- Gold badge
    WHERE 
        rp.RN <= 5
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.UserBadgeName,
    pd.UserReputation,
    pd.AnswerStatus,
    pd.PostAge
FROM 
    PostDetails pd
WHERE 
    pd.UserReputation > (
        SELECT AVG(u.Reputation) 
        FROM Users u 
        WHERE u.CreationDate < pd.CreationDate 
        AND u.Reputation IS NOT NULL
    )
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
LIMIT 10
UNION ALL
SELECT 
    DISTINCT pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    'Aggregate Score' AS UserBadgeName,
    NULL AS UserReputation,
    'Aggregate Posts' AS AnswerStatus,
    CASE 
        WHEN pd.PostAge = 'Old Post' THEN 'Older than 6 months'
        ELSE 'Recent content aggregated'
    END AS PostAge
FROM 
    PostDetails pd
WHERE 
    pd.CommentCount > (
        SELECT AVG(CommentCount) FROM PostDetails
    )
ORDER BY 
    pd.Score DESC
LIMIT 5;
