WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.Score, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.Rank,
        rp.AcceptedAnswerId,
        COALESCE(au.DisplayName, 'Unknown') AS OwnerDisplayName,
        rp.CommentCount,
        pg.CreationDate AS PostCreationDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users au ON rp.OwnerUserId = au.Id
    LEFT JOIN 
        Posts pg ON rp.PostId = pg.Id
),
TopPostDetails AS (
    SELECT 
        pd.*,
        pt.Name AS PostTypeName,
        bt.Name AS BadgeName,
        CASE 
            WHEN pd.Score > 100 THEN 'High Score'
            WHEN pd.Score BETWEEN 50 AND 100 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        PostDetails pd
    LEFT JOIN 
        PostTypes pt ON pt.Id = (SELECT p.PostTypeId FROM Posts p WHERE p.Id = pd.PostId)
    LEFT JOIN 
        Badges b ON b.UserId = pd.OwnerUserId
    LEFT JOIN 
        (SELECT DISTINCT UserId, Name FROM Badges) AS bt ON b.UserId = bt.UserId
    WHERE 
        pd.Rank <= 5
)
SELECT 
    tpd.OwnerDisplayName,
    tpd.Title, 
    tpd.ViewCount,
    tpd.Score,
    tpd.PostTypeName,
    tpd.BadgeName,
    tpd.ScoreCategory,
    CASE 
        WHEN tpd.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer Exists'
        ELSE 'No Accepted Answer'
    END AS AnswerStatus
FROM 
    TopPostDetails tpd
WHERE 
    tpd.CommentCount > 5
ORDER BY 
    tpd.ViewCount DESC
LIMIT 10;
